extends SceneTree
# V9 (10/11): el sonido del Guardián del Bosque Olvidado y del orbe del altar. Sin ventana y muda: comprueba que cada
# sonido está, cabe y se pide en su momento, no cómo se oye (eso, en docs/audio/inventario_sonidos.md, sección V9, y en
# las muestras para escuchar).
#   A. Cada clave nueva existe en sonido.gd, carga (QOA mono a su frecuencia), no satura ni es muda, cabe en su
#      presupuesto de memoria (PRESUPUESTO_KB: lo que ocupa en la RAM, data.size(), con todas sus variantes), tiene su
#      fila de procedencia (docs/audio/efectos_procedencia.csv: fuente de un paquete GDC de Sonniss, con licencia
#      comprobada, y su SHA-256) y su línea en el inventario; nada de Suno.
#   B. La voz del Guardián va por su familia («corteza») y la de los demás enemigos no cambia.
#   C. El tratamiento de su combate: lo empieza su título (el «jefe» de los demás, no), se abre en la fase 2, se calma al
#      purificarlo, el bucle se apaga con la victoria y todo se quita al irse el combate (el bus Musica queda como estaba).
#   D. En combates de verdad (grupo 11, el Guardián; el ATB parado): título y tratamiento en lugar de «jefe», su entrada
#      (con el modelo 3D), voz y latigazo al atacar, latido al cargar en lugar de «carga_jefe», las raíces al descargar,
#      rugido en la fase 2 en lugar de «fase2», derrumbe una sola vez al caer y ninguno si se purifica (su sonido).
# Datos aislados (ejecutar_pruebas.ps1); la partida en memoria.
#   Godot --headless --path aethelgard --script res://pruebas/prueba_audio_guardian.gd --fixed-fps 30

const B := preload("res://combate_bosque.gd")
const CSV := "docs/audio/efectos_procedencia.csv"          # relativo a la raíz del repositorio
const INVENTARIO := "docs/audio/inventario_sonidos.md"
# Las claves nuevas y lo que pueden ocupar en la RAM (KB, todas sus variantes; medido el 10/11 con un 30-50 % de margen)
const PRESUPUESTO_KB := {
	"guardian_bosque_jefe": 100, "guardian_bosque_entrada": 80, "guardian_bosque_ataque": 40, "guardian_bosque_golpe": 60,
	"guardian_bosque_carga": 100, "guardian_bosque_fase2": 90, "guardian_bosque_derrumbe": 90,
	"guardian_bosque_purificar": 100, "corteza_ataque": 60, "corteza_herido": 50, "corteza_caida": 70,
	"bosque_antiguo": 300, "orbe_vision": 130, "orbe_cierra": 80,
}
const TOTAL_KB := 1250                                     # todas juntas
const LICENCIAS := ["S16/", "S17/", "S18/", "S19/", "S20/", "S23/", "S24/"]   # paquetes GDC de Sonniss (PDF leído el 08/11)

var Son
var Inv
var fallos := 0
var hechos: Array = []
var pedidos: Array = []                                    # lo que pide el combate (señal sonido_pedido)
var voces: Array = []                                      # voces pedidas (señal voz_pedida): [quién, evento]
var limite_ms := 0


func _initialize() -> void:
	limite_ms = Time.get_ticks_msec() + 380 * 1000
	_probar.call_deferred()


func _process(_d: float) -> bool:
	if limite_ms > 0 and Time.get_ticks_msec() > limite_ms:
		limite_ms = 0
		_fallo("se acaba el tiempo")
		print("FALLOS: %d" % fallos)
		quit(1)
	return false


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _juego(s: float) -> void:                             # segundos de juego (con --fixed-fps 30)
	await _esperar(int(ceil(s * 30.0)))


func _n(nombre: String) -> int:
	return int(Son.contador.get(nombre, 0))


func _probar() -> void:
	Son = root.get_node("Sonido")
	Inv = load("res://inventario.gd")
	Engine.set_meta("archivo_partida_prueba", "user://prueba_audio_guardian.save")
	Engine.set_meta("partida_lista", true)
	await _esperar(3)
	_catalogo()
	_familias()
	await _tratamiento()
	await _combate_derrota()
	await _combate_purificar()
	print("OK audio del Guardián: ", ", ".join(hechos))
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _limpiar() -> void:
	for p in Son._todas():
		Son._parar_fundido(p)
		p.stop()
	Son._bajar_hasta.clear()
	Son.reiniciar_contadores()


# ---------------------------------------------------------------- A. catálogo, memoria, licencia e inventario
func _catalogo() -> void:
	var raiz := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var filas := {}
	var f := FileAccess.open(raiz.path_join(CSV), FileAccess.READ)
	if f == null:
		_fallo("A: no se puede leer %s" % CSV)
	else:
		f.get_line()
		while not f.eof_reached():
			var l := f.get_line()
			if l.strip_edges() != "":
				filas[l.get_slice(";", 0)] = l.split(";")
	var inv := FileAccess.get_file_as_string(raiz.path_join(INVENTARIO))
	var frecuencia: Dictionary = load("res://pruebas/prueba_audio_memoria.gd").FRECUENCIA
	var total := 0
	for clave in PRESUPUESTO_KB:
		var d: Dictionary = Son.EFECTOS.get(clave, {})
		if d.is_empty():
			_fallo("A: falta «%s» en sonido.gd" % clave)
			continue
		var rutas: Array = []
		if d.has("n"):
			for i in int(d["n"]):
				rutas.append(d["a"] + str(i + 1) + ".wav")
		else:
			rutas.append(d["a"] + ".wav")
		var bytes := 0
		for rel in rutas:
			var ruta: String = Son.EF + rel
			if "suno" in ruta.to_lower():
				_fallo("A: %s parece de Suno" % ruta)
			if not ResourceLoader.exists(ruta):
				_fallo("A: falta %s («%s»)" % [ruta, clave])
				continue
			var s = load(ruta)
			var hz: int = frecuencia.get(ruta, 48000)
			if not s is AudioStreamWAV or s.format != AudioStreamWAV.FORMAT_QOA or s.stereo or s.mix_rate != hz:
				_fallo("A: %s no es QOA mono a %d Hz" % [ruta, hz])
				continue
			if (s.loop_mode == AudioStreamWAV.LOOP_FORWARD) != bool(d.get("bucle", false)):
				_fallo("A: %s: el bucle no es el que dice el catálogo" % ruta)
			bytes += s.data.size()
			var w := AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(ruta))
			var b: PackedByteArray = w.data
			var pico := 0.0
			var suma := 0.0
			for i in range(0, b.size(), 2):
				var v := absf(b.decode_s16(i) / 32767.0)
				pico = maxf(pico, v)
				suma += v * v
			var rms := sqrt(suma / maxf(1.0, b.size() / 2.0))
			if pico >= 0.99 or rms < 0.002 or w.get_length() < 0.03:
				_fallo("A: %s satura o es casi mudo (pico %.2f, RMS %.4f)" % [ruta, pico, rms])
			# su procedencia: fila del CSV con fuente de un paquete con licencia comprobada y su huella
			var fila: PackedStringArray = filas.get(rel, PackedStringArray())
			if fila.size() < 9:
				_fallo("A: %s no tiene fila en %s" % [rel, CSV])
			elif not LICENCIAS.any(func(p): return fila[1].begins_with(p)) or fila[5].length() != 64:
				_fallo("A: %s: su fuente (%s) no es de un paquete con licencia comprobada o le falta la huella" % [rel, fila[1]])
		var kb := bytes / 1024.0
		total += bytes
		if kb > float(PRESUPUESTO_KB[clave]):
			_fallo("A: «%s» ocupa %.1f KB en la RAM (presupuesto %d KB)" % [clave, kb, PRESUPUESTO_KB[clave]])
		print("CLAVE %-26s %d archivo(s) · RAM %6.1f KB (presupuesto %d)" % [clave, rutas.size(), kb, PRESUPUESTO_KB[clave]])
		if not ("`%s`" % clave) in inv:
			_fallo("A: «%s» no está en %s" % [clave, INVENTARIO])
	print("TOTAL nuevas: %.1f KB (presupuesto %d KB)" % [total / 1024.0, TOTAL_KB])
	if total / 1024.0 > TOTAL_KB:
		_fallo("A: las claves nuevas ocupan %.1f KB (presupuesto %d)" % [total / 1024.0, TOTAL_KB])
	# lo que pide el combate tiene que estar (si no, _sonar callaría sin avisar)
	for k in ["guardian_bosque_entrada", "guardian_bosque_ataque", "guardian_bosque_golpe", "guardian_bosque_derrumbe"]:
		if not Son.EFECTOS.has(k):
			_fallo("A: combate pide «%s» y no está" % k)
	if Son.EFECTOS.has("guardian_bosque_aviso_golpe"):
		_fallo("A: el aviso del modelo no debe sonar (el latido ya lo pide combate: sonaría dos veces)")
	hechos.append("catálogo (%d claves, %.0f KB)" % [PRESUPUESTO_KB.size(), total / 1024.0])


# ---------------------------------------------------------------- B. la voz por familia
func _familias() -> void:
	var g := {"hero": false, "clave": "guardian_bosque", "nombre": "Guardián", "modelo": "guardian_bosque"}
	if Son.familia(g) != "corteza":
		_fallo("B: el Guardián tiene la familia «%s»" % Son.familia(g))
	var antes := {"slime": "limo", "grimfang": "goblin", "gorthor": "gorthor", "guardian": "piedra", "golem_ambar": "ambar",
		"zarzalin": "zarzalin", "posadero_hueco": "posadero"}
	for k in antes:
		if Son.familia({"hero": false, "clave": k}) != antes[k]:
			_fallo("B: la familia de «%s» ha cambiado (%s)" % [k, Son.familia({"hero": false, "clave": k})])
	for par in [["ataque", "corteza_ataque"], ["herido", "corteza_herido"], ["caida", "corteza_caida"], ["muerte", "corteza_caida"]]:
		_limpiar()
		Son.voz(g, par[0])
		if _n(par[1]) != 1:
			_fallo("B: «%s» del Guardián no suena «%s» (%s)" % [par[0], par[1], str(Son.contador)])
	_limpiar()
	g["hp"] = 0
	Son.recibe(g)
	if _n("corteza_caida") != 1:
		_fallo("B: el golpe que lo tumba no da su caída")
	_limpiar()
	hechos.append("familia «corteza» (los demás igual)")


# ---------------------------------------------------------------- C. el tratamiento
func _tratamiento() -> void:
	_limpiar()
	var i := AudioServer.get_bus_index("Musica")
	var antes := AudioServer.get_bus_effect_count(i)
	var du := Node.new()
	du.name = "CombateDeMentira"
	root.add_child(du)
	Son.efecto("jefe")
	if not Son.tratamiento_actual().is_empty():
		_fallo("C: el «jefe» de los demás pone tratamiento")
	Son.efecto("guardian_bosque_jefe", {"en": du})
	var t: Dictionary = Son.tratamiento_actual()
	if t.get("jefe", "") != "guardian_bosque" or t.get("etapa", "") != "inicio":
		_fallo("C: el título del Guardián no empieza el tratamiento (%s)" % str(t))
	if AudioServer.get_bus_effect_count(i) != antes + 2 or not AudioServer.get_bus_effect(i, 0) is AudioEffectLowPassFilter:
		_fallo("C: el bus Musica no tiene el paso bajo al principio (%d efectos)" % AudioServer.get_bus_effect_count(i))
	var bucle = Son._trata.get("bucle")
	if not is_instance_valid(bucle) or not bucle.playing or String(bucle.bus) != "Ambiente" or bucle.get_parent() != du:
		_fallo("C: el bosque antiguo no suena por Ambiente como hijo del combate")
	await _juego(3.0)
	var db0: float = Son.EFECTOS["bosque_antiguo"]["db"]
	var et: Dictionary = Son.TRATAMIENTOS["guardian_bosque"]["etapas"]
	t = Son.tratamiento_actual()
	if absf(t.get("corte", 0.0) - et["inicio"]["corte"]) > 30.0 or absf(t.get("musica_db", 0.0) - et["inicio"]["musica_db"]) > 0.3 \
			or absf(t.get("bucle_db", -99.0) - db0) > 0.3:
		_fallo("C: inicio: %s" % str(t))
	Son.efecto("guardian_bosque_fase2")
	await _juego(2.0)
	t = Son.tratamiento_actual()
	if t.get("etapa", "") != "fase2" or absf(t.get("corte", 0.0) - et["fase2"]["corte"]) > 30.0 \
			or absf(t.get("bucle_db", -99.0) - (db0 + et["fase2"]["bucle_db"])) > 0.3:
		_fallo("C: fase 2: %s" % str(t))
	Son.efecto("guardian_bosque_purificar")
	await _juego(2.3)
	t = Son.tratamiento_actual()
	if t.get("etapa", "") != "calma" or t.get("corte", 0.0) < et["calma"]["corte"] - 30.0:
		_fallo("C: purificado: %s" % str(t))
	Son.efecto("victoria")
	await _juego(2.2)
	t = Son.tratamiento_actual()
	if t.get("bucle_suena", true):
		_fallo("C: el bosque antiguo sigue sonando tras la victoria (%s)" % str(t))
	du.queue_free()
	await _esperar(4)
	if not Son.tratamiento_actual().is_empty() or AudioServer.get_bus_effect_count(i) != antes:
		_fallo("C: al irse el combate queda el tratamiento (%d efectos en Musica; antes %d)" % [AudioServer.get_bus_effect_count(i), antes])
	# sin dueño ni escena no se pone (no se quedaría puesto para siempre)
	Son.tratamiento("guardian_bosque", "inicio", null)
	if current_scene == null and not Son.tratamiento_actual().is_empty():
		_fallo("C: sin combate al que atarlo, el tratamiento se queda puesto")
	Son.quitar_tratamiento()
	_limpiar()
	hechos.append("tratamiento (inicio, fase 2, calma, fin y se quita)")


# ---------------------------------------------------------------- D. combates de verdad
func _nuevo_combate() -> Node:
	for k in ["decisiones", "combates_ganados", "hitos"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	Engine.set_meta("grupo_combate", 11)
	Engine.set_meta("combate_fijo", B.COMBATE)
	Engine.set_meta("tipo_combate", "jefe")
	Engine.set_meta("desde_mapa", false)
	_limpiar()
	pedidos.clear()
	voces.clear()
	var c = load("res://combate.tscn").instantiate()
	c.sonido_pedido.connect(func(n: String): pedidos.append(n))   # antes de entrar: la entrada se pide en _ready
	c.voz_pedida.connect(func(q: String, e: String): voces.append([q, e]))
	root.add_child(c)
	await _esperar(30)
	for x in c.heroes + c.enemigos:
		x["vel"] = 0.0
		x["atb"] = 0.0
		if x["hero"]:
			x["hp_max"] = 9999
			x["hp"] = 9999
	c.cola.clear()
	return c


func _guardian(c) -> Dictionary:
	for e in c.enemigos:
		if B.es_guardian(e):
			return e
	return {}


func _vivos(c) -> Array:
	return c.heroes.filter(func(h): return h["hp"] > 0)


func _combate_derrota() -> void:
	var c = await _nuevo_combate()
	var g := _guardian(c)
	if g.is_empty():
		_fallo("D: el grupo 11 no trae al Guardián")
		c.queue_free()
		return
	var tres_d: bool = c._p3d(g) != null
	print("MODELO del Guardián: %s" % ("3D" if tres_d else "2D de respaldo"))
	if _n("guardian_bosque_jefe") != 1 or _n("jefe") != 0:
		_fallo("D: título: guardian_bosque_jefe %d, jefe %d" % [_n("guardian_bosque_jefe"), _n("jefe")])
	if Son.tratamiento_actual().get("jefe", "") != "guardian_bosque":
		_fallo("D: el combate del Guardián no tiene su tratamiento")
	if tres_d and (not "guardian_bosque_entrada" in pedidos or _n("guardian_bosque_entrada") != 1):
		_fallo("D: su entrada no suena una vez (%d)" % _n("guardian_bosque_entrada"))
	# ataca: su voz al alzar la rama y el latigazo en el impacto (señal del modelo)
	_limpiar()
	pedidos.clear()
	await c._anim_guardian(g, func(): pass, "ataque")
	if _n("corteza_ataque") != 1 or not voces.any(func(v): return v[1] == "ataque"):
		_fallo("D: al atacar no suena su voz «corteza_ataque» (%d)" % _n("corteza_ataque"))
	if tres_d and (not "guardian_bosque_ataque" in pedidos or _n("guardian_bosque_ataque") != 1):
		_fallo("D: el latigazo no suena una vez en el impacto (%s)" % str(pedidos))
	# carga: el latido (no «carga_jefe»); descarga: las raíces
	_limpiar()
	pedidos.clear()
	seed(5)
	var intentos := 0
	while not g.get("cargando", false) and intentos < 14:
		intentos += 1
		await c._turno_guardian(g, _vivos(c), 1.0)
	if not g.get("cargando", false):
		_fallo("D: en %d turnos no carga" % intentos)
	else:
		if _n("guardian_bosque_carga") != 1 or _n("carga_jefe") != 0:
			_fallo("D: carga: guardian_bosque_carga %d, carga_jefe %d" % [_n("guardian_bosque_carga"), _n("carga_jefe")])
		pedidos.clear()
		await c._turno_guardian(g, _vivos(c), 1.0)
		if tres_d and not "guardian_bosque_golpe" in pedidos:
			_fallo("D: al descargar no brotan las raíces (%s)" % str(pedidos))
	# fase 2: su rugido (no «fase2») y el tratamiento se abre
	_limpiar()
	c._quitar_pv(g, g["hp"] - int(g["hp_max"] * 0.45))
	var t0 := Time.get_ticks_msec()
	while (g.get("fase2_pendiente", false) or c.estado == "accion") and Time.get_ticks_msec() - t0 < 30000:
		await process_frame
	await _juego(0.5)
	if not g.get("fase2", false) or _n("guardian_bosque_fase2") != 1 or _n("fase2") != 0:
		_fallo("D: fase 2: guardian_bosque_fase2 %d, fase2 %d" % [_n("guardian_bosque_fase2"), _n("fase2")])
	if Son.tratamiento_actual().get("etapa", "") != "fase2":
		_fallo("D: en la fase 2 el tratamiento no se abre (%s)" % str(Son.tratamiento_actual()))
	# derrota: se desmorona una vez
	_limpiar()
	pedidos.clear()
	c._quitar_pv(g, g["hp"])
	c._restablecer_color(g)
	c._restablecer_color(g)
	if pedidos.count("guardian_bosque_derrumbe") != 1 or _n("guardian_bosque_derrumbe") != 1:
		_fallo("D: el derrumbe no suena una sola vez (%d pedidos)" % pedidos.count("guardian_bosque_derrumbe"))
	c.queue_free()
	await _esperar(5)
	if not Son.tratamiento_actual().is_empty():
		_fallo("D: al acabar el combate queda el tratamiento")
	hechos.append("combate derrotado (%s)" % ("3D" if tres_d else "2D"))


func _combate_purificar() -> void:
	var c = await _nuevo_combate()
	var g := _guardian(c)
	if g.is_empty():
		c.queue_free()
		return
	c._quitar_pv(g, g["hp"] - int(g["hp_max"] * 0.4))
	var t0 := Time.get_ticks_msec()
	while (g.get("fase2_pendiente", false) or c.estado == "accion") and Time.get_ticks_msec() - t0 < 30000:
		await process_frame
	await _juego(0.5)
	_limpiar()
	pedidos.clear()
	Inv.agregar_objeto(B.ELIXIR, 1)
	c.actor = c.heroes[0]
	await c._usar_elixir(B.ELIXIR, g)
	await _juego(0.5)
	if _n("guardian_bosque_purificar") != 1:
		_fallo("D: al purificarlo no suena «guardian_bosque_purificar» (%d)" % _n("guardian_bosque_purificar"))
	if "guardian_bosque_derrumbe" in pedidos or _n("guardian_bosque_derrumbe") != 0:
		_fallo("D: purificado, se desmorona igual")
	var t: Dictionary = Son.tratamiento_actual()
	if not t.is_empty() and not t.get("etapa", "") in ["calma", "fin"]:
		_fallo("D: purificado, el tratamiento no se calma (%s)" % str(t))
	c.queue_free()
	await _esperar(5)
	hechos.append("combate purificado")
