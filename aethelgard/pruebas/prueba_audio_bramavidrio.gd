extends SceneTree
# V12 (12/11): la identidad sonora de Bramavidrio (EFECTOS_BRAMAVIDRIO de sonido.gd, OGG de audio/bramavidrio/, y los
# instantes en que los pide combate_bramavidrio.gd, SONIDOS). Sin ventana y muda: comprueba que cada sonido está, carga,
# dura lo que debe, no satura, empieza cuando debe y se pide en su instante una sola vez; NO cómo se oye (eso, en las
# muestras: docs/memory/agents/sonido_v12_bramavidrio.md).
#   A. Catálogo: cada clave existe (definicion()), no pisa EFECTOS ni EFECTOS_DESIERTO, va por un bus de sonido.gd y cada
#      archivo es un AudioStreamOggVorbis de audio/bramavidrio/ con su duración, en bucle solo si «en_bucle», dentro del
#      presupuesto y con su fila en el informe; SONIDOS (combate_bramavidrio.gd) solo nombra claves que existen.
#   B. Señal decodificada (mix_audio): ni muda ni saturada; el bucle sigue al dar la vuelta y lo demás calla; los golpes
#      arrancan en sus primeros 0,15 s, el rugido llega a su pico en el primer segundo (sale con rugido_pico) y la caída
#      de la Fractura crece hasta el final (llega al golpe).
#   C. En un combate de verdad (grupo 13), con la identidad propia y con la de antes (Engine.set_meta
#      «bramavidrio_sonido»), con el combate quieto (estado «accion») y los ataques llamados uno a uno: la entrada, la
#      Embestida (se recoge, fija, latigazo e impacto, en orden y en sus instantes del clip), el aviso y la Fractura
#      (rugido, caída, impacto, placas y asiento), el aviso y el Aliento (succión y su bucle, que se corta en fin_succion,
#      chorro y un «alcanza» por héroe), el corte (se atraganta y el bucle calla), el jadeo, su voz (herido y caída) y el
#      derrumbe; cada uno una vez, por el bus Efectos, sin descartes y sin sonidos de la otra identidad.
# Datos aislados (ejecutar_pruebas.ps1); no guarda partida. Sirve con las dos versiones del modelo («bramavidrio_version»).
#   Godot --headless --path aethelgard --script res://pruebas/prueba_audio_bramavidrio.gd --fixed-fps 30

const INFORME := "docs/memory/agents/sonido_v12_bramavidrio.md"   # relativo a la raíz del repositorio
const ARCHIVO := "user://prueba_audio_bramavidrio.save"
# clave → [duración mínima, máxima] (s, cada variante)
const ESPERADO := {
	"brama_rugido": [4.0, 8.0], "brama_herido": [0.8, 2.6], "brama_caida": [4.0, 8.0], "brama_jadeo": [2.0, 5.0],
	"brama_atraganta": [1.2, 3.5], "brama_emerge": [3.0, 7.0], "brama_derrumbe": [4.0, 8.0], "brama_recoge": [0.6, 2.5],
	"brama_fija": [0.5, 2.0], "brama_latigazo": [0.5, 2.0], "brama_surco": [0.9, 3.0], "brama_embestida": [1.2, 3.0],
	"brama_caida_aire": [0.4, 0.7], "brama_fractura": [3.5, 8.0], "brama_placas": [2.0, 5.0],
	"brama_placas_asientan": [1.0, 3.0], "brama_succion": [2.0, 5.0], "brama_succion_bucle": [4.0, 10.0],
	"brama_chorro": [2.0, 4.5], "brama_arena_alcanza": [0.5, 1.5],
}
const ARRANCA := ["brama_embestida", "brama_fractura", "brama_chorro", "brama_arena_alcanza", "brama_herido", "brama_fija",
	"brama_atraganta", "brama_emerge", "brama_derrumbe", "brama_placas", "brama_rugido"]
const PRESUPUESTO_KB := 1300                               # todos los OGG juntos (medido el 12/11: ~1 100 KB)
const T := 30.0                                            # fotogramas por segundo (--fixed-fps 30)

var Son
var B
var P
var G
var c = null
var z = null
var fallos := 0
var hechos: Array = []
var limite_ms := 0
var pedidos: Array = []                                    # [nombre, fotograma, clip, s del clip] (señal sonido_pedido)


func _initialize() -> void:
	limite_ms = Time.get_ticks_msec() + 280 * 1000
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	B = load("res://combate_bramavidrio.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
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


func _ok(cond: bool, t: String) -> void:
	if not cond:
		_fallo(t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _probar() -> void:
	Son = root.get_node("Sonido")
	await _esperar(3)
	_catalogo()
	_senal()
	for identidad in ["propio", "anterior"]:
		await _combate_de_prueba(identidad)
	Engine.remove_meta("bramavidrio_sonido")
	Engine.remove_meta("archivo_partida_prueba")
	print("OK audio de Bramavidrio (versión %d del modelo): %s" % [load("res://enemigos/bramavidrio/bramavidrio_version.gd").version(),
		", ".join(hechos)])
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _rutas(clave: String) -> Array:
	var d: Dictionary = Son.definicion(clave)
	var r: Array = []
	if d.has("n"):
		for i in int(d["n"]):
			r.append(Son.ruta_archivo(d, i))
	else:
		r.append(Son.ruta_archivo(d))
	return r


# ---------------------------------------------------------------- A. catálogo
func _catalogo() -> void:
	var raiz := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var informe := FileAccess.get_file_as_string(raiz.path_join(INFORME))
	_ok(informe != "", "A: no se puede leer %s" % INFORME)
	_ok(Son.EFECTOS_BRAMAVIDRIO.size() == ESPERADO.size(), "A: EFECTOS_BRAMAVIDRIO tiene %d claves (esperaba %d)" % [
		Son.EFECTOS_BRAMAVIDRIO.size(), ESPERADO.size()])
	var bytes := 0
	for clave in ESPERADO:
		var d: Dictionary = Son.definicion(clave)
		if d.is_empty() or not Son.EFECTOS_BRAMAVIDRIO.has(clave):
			_fallo("A: falta «%s» en sonido.gd (EFECTOS_BRAMAVIDRIO)" % clave)
			continue
		_ok(not Son.EFECTOS.has(clave) and not Son.EFECTOS_DESIERTO.has(clave), "A: «%s» está también en otro catálogo" % clave)
		_ok(String(d.get("bus", "Efectos")) == "Efectos", "A: «%s» no va por Efectos" % clave)
		var bucle: bool = bool(d.get("en_bucle", false))
		var e: Array = ESPERADO[clave]
		for ruta in _rutas(clave):
			_ok(not "suno" in ruta.to_lower(), "A: %s parece de Suno" % ruta)
			_ok(ruta.begins_with(Son.BRAMA) and ruta.get_extension() == "ogg", "A: %s no es un OGG de %s" % [ruta, Son.BRAMA])
			if not ResourceLoader.exists(ruta):
				_fallo("A: falta %s («%s»)" % [ruta, clave])
				continue
			var s = load(ruta)
			if not s is AudioStreamOggVorbis:
				_fallo("A: %s no carga como AudioStreamOggVorbis" % ruta)
				continue
			var largo: float = s.get_length()
			_ok(largo >= float(e[0]) and largo <= float(e[1]), "A: %s dura %.2f s (esperaba %.2f-%.2f)" % [ruta, largo, e[0], e[1]])
			_ok(s.loop == bucle, "A: %s %s está marcado como bucle (.import)" % [ruta, "no" if bucle else "sí y no debería"])
			var f := FileAccess.open(ruta, FileAccess.READ)
			if f != null:
				bytes += f.get_length()
			_ok(ruta.get_file() in informe, "A: %s no tiene su fila en %s" % [ruta.get_file(), INFORME])
			print("ARCHIVO %-46s %5.2f s  bucle %-5s %6.1f KB" % [ruta, largo, s.loop, (f.get_length() if f else 0) / 1024.0])
	_ok(bytes / 1024.0 <= PRESUPUESTO_KB, "A: los OGG de Bramavidrio ocupan %.0f KB (presupuesto %d)" % [bytes / 1024.0, PRESUPUESTO_KB])
	for palabra in ["Sonniss", "GDC", "licencia", "SHA-256"]:
		_ok(palabra in informe, "A: el informe no habla de «%s»" % palabra)
	for ev in B.SONIDOS:
		var par: Array = B.SONIDOS[ev]
		_ok(Son.EFECTOS_BRAMAVIDRIO.has(par[0]), "A: SONIDOS[«%s»] pide «%s», que no está en EFECTOS_BRAMAVIDRIO" % [ev, par[0]])
		_ok(par[1] == "" or Son.EFECTOS.has(par[1]) or Son.EFECTOS_DESIERTO.has(par[1]),
			"A: SONIDOS[«%s»]: lo de antes («%s») no existe" % [ev, par[1]])
	print("OGG de Bramavidrio: %.0f KB" % (bytes / 1024.0))
	hechos.append("catálogo (%d claves, %.0f KB)" % [ESPERADO.size(), bytes / 1024.0])


# ---------------------------------------------------------------- B. señal decodificada
func _senal() -> void:
	var probe: AudioStreamPlayback = (load(_rutas("brama_fija")[0]) as AudioStream).instantiate_playback()
	if probe == null or not probe.has_method("mix_audio"):
		print("AVISO: este Godot no tiene AudioStreamPlayback.mix_audio: la señal no se mide aquí (sí en el informe)")
		return
	var hz := AudioServer.get_mix_rate()
	var bloque := int(0.02 * hz)
	for clave in ESPERADO:
		var bucle: bool = bool(Son.definicion(clave).get("en_bucle", false))
		for ruta in _rutas(clave):
			var s: AudioStream = load(ruta)
			if s == null:
				continue
			var pb := s.instantiate_playback()
			pb.start(0.0)
			var n := int(s.get_length() * hz)
			var extra := int(0.5 * hz)
			var buf: PackedVector2Array = pb.mix_audio(1.0, n + extra)
			if buf.size() < n - int(0.01 * hz):
				_fallo("B: %s: solo se decodifican %d de %d muestras" % [ruta, buf.size(), n])
				continue
			n = mini(n, buf.size())
			var pico := 0.0
			var suma := 0.0
			var bloques: Array = []                            # energía de cada 20 ms
			var acc := 0.0
			for i in n:
				var a2 := buf[i].x * buf[i].x + buf[i].y * buf[i].y
				pico = maxf(pico, maxf(absf(buf[i].x), absf(buf[i].y)))
				suma += a2
				acc += a2
				if (i + 1) % bloque == 0:
					bloques.append(acc)
					acc = 0.0
			var rms := 10.0 * log(suma / (2.0 * n) + 1e-20) / log(10.0)
			var pico_db := 20.0 * log(pico + 1e-12) / log(10.0)
			var cola := 0.0
			for i in range(n, mini(buf.size(), n + extra)):
				cola += buf[i].x * buf[i].x + buf[i].y * buf[i].y
			var cola_db := 10.0 * log(cola / (2.0 * extra) + 1e-20) / log(10.0)
			var inicio := 0.0
			for i in mini(extra, n):
				inicio += buf[i].x * buf[i].x + buf[i].y * buf[i].y
			var inicio_db := 10.0 * log(inicio / (2.0 * extra) + 1e-20) / log(10.0)
			var mx := 0.0
			var i_mx := 0
			for k in bloques.size():
				if bloques[k] > mx:
					mx = bloques[k]
					i_mx = k
			var arranque := -1.0                               # primer bloque a 12 dB o menos del más fuerte
			for k in bloques.size():
				if bloques[k] >= mx * 0.063:
					arranque = k * 0.02
					break
			print("SEÑAL %-24s pico %6.1f dBFS  RMS %6.1f  arranca %.2f s  pico de energía %.2f s  tras el final %6.1f" % [
				ruta.get_file(), pico_db, rms, arranque, i_mx * 0.02, cola_db])
			_ok(rms > -45.0, "B: %s casi mudo (RMS %.1f dBFS)" % [ruta, rms])
			_ok(pico_db <= -0.3, "B: %s satura (pico %.1f dBFS)" % [ruta, pico_db])
			if bucle:
				_ok(cola_db > -60.0 and absf(cola_db - inicio_db) < 3.0, "B: %s no vuelve a empezar al dar la vuelta (%.1f / %.1f)" % [
					ruta, cola_db, inicio_db])
			else:
				_ok(cola_db < -70.0, "B: %s sigue sonando después del final (%.1f dBFS)" % [ruta, cola_db])
			if clave in ARRANCA:
				_ok(arranque >= 0.0 and arranque <= 0.15, "B: %s tarda %.2f s en arrancar (su instante es el del golpe)" % [ruta, arranque])
			if clave == "brama_rugido":
				_ok(i_mx * 0.02 <= 1.0, "B: %s llega a su pico a los %.2f s (sale con rugido_pico: debe estar arriba ya)" % [
					ruta, i_mx * 0.02])
			if clave == "brama_caida_aire":
				_ok(i_mx * 0.02 >= 0.3, "B: la caída no crece hasta el golpe (pico a %.2f s)" % (i_mx * 0.02))
	hechos.append("señal")


# ---------------------------------------------------------------- C. en un combate de verdad
# Cada petición se apunta con el clip del modelo y su posición en ese momento: el aviso y el ataque son el mismo clip
# (avisar lo para en su aviso y atacar sigue desde ahí), así que el instante se mira en el clip, no en el reloj.
const INSTANTE := {
	"brama_recoge": ["ataque", 0.2], "brama_fija": ["ataque", 0.55], "brama_latigazo": ["ataque", 0.8],
	"brama_embestida": ["ataque", 1.0], "brama_caida_aire": ["ataque_sismico", 2.1],
	"brama_fractura": ["ataque_sismico", 2.5333], "brama_placas": ["ataque_sismico", 2.5333],
	"brama_placas_asientan": ["ataque_sismico", 3.1], "brama_chorro": ["ataque_aliento", 1.85],
	"brama_succion": ["ataque_aliento", 0.45], "brama_succion_bucle": ["ataque_aliento", 0.45],
	"brama_rugido": ["ataque_sismico", 1.25],
}
const INSTANTE_ANTES := {"gusano_rugido": ["ataque_aliento", 1.85]}   # (lo de antes: el chorro; el temblor, en varios)
const TOL_S := 0.12                                        # s de tolerancia en el clip (~4 fotogramas a 30)


func _limpiar_metas() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _cuenta(nombre: String, desde := 0) -> Array:
	return pedidos.slice(desde).filter(func(x): return x[0] == nombre)


# «nombre» se pide una vez desde «desde» y, si se sabe su instante, en ese punto de su clip.
func _uno(nombre: String, desde: int, que: String, instantes := INSTANTE) -> void:
	var l := _cuenta(nombre, desde)
	_ok(l.size() == 1, "C: %s: «%s» se pide %d veces (debía 1)" % [que, nombre, l.size()])
	if l.size() == 1 and instantes.has(nombre):
		var e: Array = instantes[nombre]
		var x: Array = l[0]
		_ok(x[2] == e[0] and absf(float(x[3]) - float(e[1])) <= TOL_S, "C: %s: «%s» suena en «%s» %.2f s (esperaba «%s» %.2f s)" % [
			que, nombre, x[2], x[3], e[0], e[1]])
		print("INSTANTE %-24s clip %-16s %.3f s (esperado %.3f)" % [nombre, x[2], x[3], e[1]])


func _sonando(nombre: String) -> bool:
	for p in Son._todas():
		if p.playing and p.get_meta("efecto", "") == nombre and not p.get_meta("apagando", false):
			return true
	return false


# Sin ventana, el controlador de audio de prueba no avanza la reproducción (se mira abajo): lo que suena no acaba y los
# reproductores se llenan. Entre un paso y otro (en el juego pasan turnos enteros) se paran a mano.
func _silencio() -> void:
	for p in Son._todas():
		Son._parar_fundido(p)
		p.stop()
	Son._bajar_hasta.clear()


func _combate_de_prueba(identidad: String) -> void:
	var propio := identidad == "propio"
	Engine.set_meta("bramavidrio_sonido", identidad)
	_ok(Son.identidad_bramavidrio() == propio, "C: el interruptor no cambia la identidad (%s)" % identidad)
	_limpiar_metas()
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	for n in ["Kael", "Lya", "Garon"]:
		G.datos()[n]["nivel"] = 30                         # que nadie caiga mientras se mira
		G.datos()[n]["exp"] = 0
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("combates_ganados", {})
	Engine.set_meta("zona", "desierto")
	Engine.set_meta("tipo_combate", "jefe")
	Engine.set_meta("grupo_combate", B.GRUPO)
	Engine.set_meta("combate_fijo", B.COMBATE)
	seed(97)
	_silencio()
	Son.reiniciar_contadores()
	pedidos.clear()
	c = load("res://combate.tscn").instantiate()
	c.sonido_pedido.connect(func(n: String):
		var m = c._p3d(c.enemigos[0]) if c != null and not c.enemigos.is_empty() else null
		var clip := ""
		var pos := -1.0
		if m != null and m.anim != null:
			clip = String(m.anim.current_animation)
			pos = m.anim.current_animation_position
		pedidos.append([n, Engine.get_process_frames(), clip, pos]))
	root.add_child(c)
	z = c.enemigos[0]
	var zp = c._p3d(z)
	await _esperar(int(2.0 * T))                           # la entrada: emerge y ruge (0,9 s)
	c.estado = "accion"                                    # nadie actúa mientras se mira: los ataques se llaman aquí
	var br = c.brama
	if br == null or zp == null:
		_fallo("C: sin Bramavidrio o sin su modelo 3D en el combate")
		return
	# ¿avanza la reproducción sin ventana? (diagnóstico: por qué se paran los reproductores entre pasos)
	var avanza := "nada sonando"
	for p in Son._todas():
		if p.playing:
			avanza = "«%s» en %.2f s tras ~1-2 s" % [p.get_meta("efecto", "?"), p.get_playback_position()]
			break
	print("REPRODUCCIÓN sin ventana: ", avanza)
	var vivos: Array = c.heroes.filter(func(h): return h["hp"] > 0)
	var nombre := func(ev: String) -> String: return B.SONIDOS[ev][0] if propio else B.SONIDOS[ev][1]
	# la entrada
	if propio:
		_uno("brama_emerge", 0, "entrada")
		_ok(_cuenta("brama_rugido").size() == 1, "C: la entrada no ruge una vez")
	else:
		_ok(_cuenta("gusano_temblor").size() == 1 and _cuenta("gusano_rugido").size() == 1, "C: la entrada de antes no suena igual")
	await _esperar(int(0.8 * T))                           # (el rugido de la entrada tiene 2 s de espera)
	# 1. Embestida: se recoge (0,2), fija (0,55), se lanza (0,8), impacto (1,0)
	_silencio()
	var i0 := pedidos.size()
	var obj: Dictionary = vivos.filter(func(h): return h["nombre"] == "Lya")[0]
	var d0 := int(br.contador.get("desliza", 0))
	await br.animar_golpe(obj, func(): pass)
	if propio:
		for n in ["brama_recoge", "brama_fija", "brama_latigazo", "brama_embestida"]:
			_uno(n, i0, "Embestida")
		var n_surco := _cuenta("brama_surco", i0).size()
		_ok(n_surco == int(br.contador.get("desliza", 0)) - d0, "C: Embestida: el surco suena %d veces y avanza %d" % [n_surco,
			int(br.contador.get("desliza", 0)) - d0])
		var orden: Array = pedidos.slice(i0).map(func(x): return x[0]).filter(func(n): return n in ["brama_recoge",
			"brama_fija", "brama_latigazo", "brama_embestida"])
		_ok(orden == ["brama_recoge", "brama_fija", "brama_latigazo", "brama_embestida"], "C: Embestida en otro orden: %s" % [orden])
	else:
		_uno("gusano_temblor", i0, "Embestida (antes)")
	await _esperar(int(1.0 * T))
	# 2. aviso de la Fractura (rugido en rugido_pico) y la Fractura
	_silencio()
	i0 = pedidos.size()
	await br._avisar("sismico", vivos)
	_uno(nombre.call("rugido"), i0, "aviso de la Fractura")
	await _esperar(int(0.5 * T))
	_silencio()
	i0 = pedidos.size()
	var vigilar := {"max_efectos": 0}
	var t_mirar := Timer.new()
	t_mirar.wait_time = 1.0 / T
	t_mirar.timeout.connect(func(): vigilar["max_efectos"] = maxi(int(vigilar["max_efectos"]), Son.sonando("Efectos")))
	root.add_child(t_mirar)
	t_mirar.start()
	await br._fractura(vivos, 1.0)
	t_mirar.stop()
	if propio:
		for n in ["brama_caida_aire", "brama_fractura", "brama_placas", "brama_placas_asientan"]:
			_uno(n, i0, "Fractura")
		_ok(_cuenta("brama_rugido", i0).is_empty(), "C: Fractura: ruge otra vez al caer")
	else:
		_uno("gusano_temblor", i0, "Fractura (antes)")
	print("C (%s): en la Fractura suenan a la vez como mucho %d efectos (reproductores de Efectos: %d)" % [identidad,
		int(vigilar["max_efectos"]), Son.VOCES["Efectos"]])
	await _esperar(int(1.0 * T))
	# 3. aviso del Aliento (succión y su bucle) y el Aliento (fin_succion 1,7: el bucle calla; chorro 1,85)
	_silencio()
	i0 = pedidos.size()
	await br._avisar("aliento", vivos)
	await _esperar(int(0.3 * T))
	_uno(nombre.call("succion"), i0, "aviso del Aliento")
	if propio:
		_uno(B.BUCLE_SUCCION, i0, "aviso del Aliento (bucle)")
		await _esperar(int(1.5 * T))
		_ok(_sonando(B.BUCLE_SUCCION), "C: el bucle de la succión no sigue sonando mientras aspira")
	else:
		_ok(_cuenta(B.BUCLE_SUCCION, i0).is_empty(), "C: con lo de antes suena el bucle de la succión")
	i0 = pedidos.size()
	var estado := {"calla": ""}
	var t2 := Timer.new()
	t2.wait_time = 1.0 / T
	t2.timeout.connect(func():
		var m = c._p3d(z)
		if estado["calla"] == "" and not _sonando(B.BUCLE_SUCCION) and m != null and m.anim != null:
			estado["calla"] = "%s %.2f" % [m.anim.current_animation, m.anim.current_animation_position])
	root.add_child(t2)
	t2.start()
	var en_pie: int = vivos.filter(func(h): return h["hp"] > 0).size()
	await br._aliento(vivos, 1.0)
	await _esperar(int(1.0 * T))
	t2.queue_free()
	_uno(nombre.call("chorro"), i0, "Aliento", INSTANTE if propio else INSTANTE_ANTES)
	if propio:
		var calla: String = estado["calla"]
		var pos_calla := float(calla.get_slice(" ", 1)) if calla != "" else -1.0
		_ok(calla.begins_with("ataque_aliento") and pos_calla >= 1.6 and pos_calla <= 1.95,
			"C: el bucle de la succión no calla en fin_succion (1,7 s; calla en «%s»)" % calla)
		print("INSTANTE %-24s clip %s" % ["(el bucle calla)", calla])
		_ok(_cuenta("brama_arena_alcanza", i0).size() == en_pie, "C: el chorro alcanza a %d y suena %d veces" % [en_pie,
			_cuenta("brama_arena_alcanza", i0).size()])
	# 4. el corte: se atraganta y el bucle calla
	_silencio()
	i0 = pedidos.size()
	await br._avisar("aliento", vivos)
	await _esperar(int(0.6 * T))
	br.cortar("¡Interrumpido!", "prueba")
	await _esperar(int(0.6 * T))
	if propio:
		_uno("brama_atraganta", i0, "corte")
		_ok(not _sonando(B.BUCLE_SUCCION), "C: tras el corte sigue sonando el bucle de la succión")
	# 5. el turno que jadea
	_silencio()
	i0 = pedidos.size()
	await br.turno(vivos, 1.0)
	if propio:
		_uno("brama_jadeo", i0, "jadeo")
	await _esperar(int(0.5 * T))
	# 6. su voz: herido (sus variantes, sin repetir la anterior) y caída; y el derrumbe (caida del clip de derrota, 1,6 s)
	_silencio()
	var voces := {}
	var archivos_herido := {}
	for k in 4:
		Son._ultimo.clear()
		var p = Son.voz(z, "herido")
		if p != null:
			voces[String(p.get_meta("efecto", ""))] = true
			archivos_herido[String(Son.registro[-1][2])] = true
		await _esperar(int(0.4 * T))
	var fam := "brama" if propio else "piedra"
	_ok(voces.keys() == [fam + "_herido"], "C: su voz de herido no es la de «%s» (%s; descartes %s)" % [fam, voces.keys(), Son.descartes])
	if propio:
		_ok(archivos_herido.size() >= 2, "C: cuatro quejidos seguidos usan una sola variante (%s)" % [archivos_herido.keys()])
	_silencio()
	i0 = pedidos.size()
	z["hp"] = 0
	Son.recibe(z)
	_ok(Son.registro.size() > 0 and String(Son.registro[-1][1]) == fam + "_caida", "C: su voz al caer no es «%s_caida» (%s)" % [
		fam, Son.registro[-1][1] if Son.registro.size() > 0 else "nada"])
	c._restablecer_color(z)
	await _esperar(int(2.6 * T))
	_uno(nombre.call("derrumbe"), i0, "derrota")
	# nada de la otra identidad, todo por Efectos y sin descartes
	for x in pedidos:
		var n: String = x[0]
		if propio:
			_ok(not n.begins_with("gusano_"), "C: con la identidad propia se pide «%s»" % n)
		else:
			_ok(not n.begins_with("brama_"), "C: con lo de antes se pide «%s»" % n)
	for k in Son.descartes:
		_ok(not String(k).begins_with("brama_"), "C: se descarta «%s» (%d)" % [k, Son.descartes[k]])
	var usados := {}
	for r in Son.registro:
		if String(r[1]).begins_with("brama_"):
			_ok(String(r[3]) == "Efectos", "C: «%s» suena por %s" % [r[1], r[3]])
			usados[r[2]] = true
	print("C (%s): %d sonidos pedidos; archivos de Bramavidrio que han sonado: %d; descartes: %s" % [identidad,
		pedidos.size(), usados.size(), Son.descartes])
	t_mirar.queue_free()
	c.queue_free()
	c = null
	await _esperar(10)
	_ok(not _sonando(B.BUCLE_SUCCION), "C: al cerrar el combate sigue el bucle de la succión")
	_silencio()
	_limpiar_metas()
	hechos.append("combate (%s)" % identidad)
