extends SceneTree
# V12 (12/11): el sonido de la magia negra (EFECTOS_MAGIA_NEGRA de sonido.gd, OGG de audio/magia_negra/, y las claves que
# piden combate.gd y magia_negra.gd). Sin ventana y muda: comprueba que cada sonido está, carga, dura lo que debe, no
# satura, empieza cuando debe, va por el bus Efectos, no se duplica y se pide una sola vez por hechizo; NO cómo se oye
# (eso, en las muestras y montajes: docs/memory/agents/sonido_v12_magia_negra.md).
#   A. Catálogo: las 14 claves existen (definicion()), solo en EFECTOS_MAGIA_NEGRA, por Efectos, prioridad 2-3 (nunca 4:
#      una victoria las baja), un máximo de 1 a la vez; cada archivo es un AudioStreamOggVorbis de audio/magia_negra/,
#      sin bucle, con su duración, dentro del presupuesto y con su fila en el informe. Las tablas de magia_negra.gd
#      (SONIDO, SONIDO_FORMA, SONIDO_PREPARAR, SONIDO_ROTO) piden exactamente estas claves, y con la comprobación de
#      combate.gd (_existe_sonido) los 24 hechizos, preparar y la rotura eligen la clave nueva, no el respaldo. Papeles:
#      los avanzados por encima de las escuelas; preparar, lo más bajo.
#   B. Señal decodificada (mix_audio): ni muda ni saturada, calla al acabar, mismo nivel de archivo (energía sin ponderar
#      en 400 ms, 4 dB entre todos como mucho: el nivel común es en LUFS, que pesa distinto los graves), los golpes arrancan en sus primeros 0,15 s y preparar crece (sin golpe al principio).
#   C. Reproducción (Sonido.efecto): por el bus Efectos con su volumen; pedida dos veces seguidas suena una (no se
#      duplica); las escuelas alternan sus dos variantes; en pausa, nada.
#   D. En un combate de verdad (grupo 1, Kael con el interruptor de pruebas), con el combate parado: los 24 hechizos uno
#      tras otro piden su clave nueva una sola vez y suena una vez (sin descartes); preparar (Lluvia de Brasas) y la
#      rotura del conjuro (un golpe del 25 %), igual.
# Datos aislados (ejecutar_pruebas.ps1); no guarda partida.
#   Godot --headless --path aethelgard --script res://pruebas/prueba_audio_magia_negra.gd --fixed-fps 30

const INFORME := "docs/memory/agents/sonido_v12_magia_negra.md"   # relativo a la raíz del repositorio
const ARCHIVO := "user://prueba_audio_magia_negra.save"
# clave → [duración mínima, máxima] (s, cada variante)
const ESPERADO := {
	"negra_fuego": [1.8, 4.5], "negra_hielo": [1.8, 4.5], "negra_rayo": [1.8, 4.5], "negra_sombras": [1.8, 4.5],
	"negra_gravedad": [1.8, 5.0], "negra_maldicion": [1.8, 5.0], "negra_prision": [2.0, 5.0],
	"negra_sol_ceniza": [3.5, 8.0], "negra_invierno": [3.5, 8.0], "negra_juicio": [3.5, 8.0], "negra_noche": [3.5, 8.0], "naira_eclipse": [3.5, 8.0],   # naira_eclipse: provisional, el de Noche Absoluta
	"negra_colapso": [3.5, 8.0], "negra_preparar": [1.5, 4.5], "negra_conjuro_roto": [1.0, 3.5],
}
const ESCUELAS := ["negra_fuego", "negra_hielo", "negra_rayo", "negra_sombras", "negra_gravedad", "negra_maldicion"]
const AVANZADOS := ["negra_sol_ceniza", "negra_invierno", "negra_juicio", "negra_noche", "negra_colapso"]
const SIN_GOLPE := ["negra_preparar"]                     # crece: no arranca con un golpe
const PRESUPUESTO_KB := 1300                               # todos los OGG juntos (medido el 12/11: ~1 090 KB)

var Son
var MN
var P
var G
var c = null
var fallos := 0
var hechos: Array = []
var limite_ms := 0
var pedidos: Array = []                                    # señal sonido_pedido de combate.gd


func _initialize() -> void:
	limite_ms = Time.get_ticks_msec() + 280 * 1000
	MN = load("res://magia_negra.gd")
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
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
	await _reproduccion()
	await _combate()
	_limpiar_metas()
	Engine.remove_meta("archivo_partida_prueba")
	print("OK audio de la magia negra: %s" % ", ".join(hechos))
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
	_ok(Son.EFECTOS_MAGIA_NEGRA.size() == ESPERADO.size(), "A: EFECTOS_MAGIA_NEGRA tiene %d claves (esperaba %d)" % [
		Son.EFECTOS_MAGIA_NEGRA.size(), ESPERADO.size()])
	var bytes := 0
	var archivos := 0
	for clave in ESPERADO:
		var d: Dictionary = Son.definicion(clave)
		if d.is_empty() or not Son.EFECTOS_MAGIA_NEGRA.has(clave):
			_fallo("A: falta «%s» en sonido.gd (EFECTOS_MAGIA_NEGRA)" % clave)
			continue
		_ok(not Son.EFECTOS.has(clave) and not Son.EFECTOS_DESIERTO.has(clave) and not Son.EFECTOS_BRAMAVIDRIO.has(clave),
			"A: «%s» está también en otro catálogo" % clave)
		_ok(String(d.get("bus", "Efectos")) == "Efectos", "A: «%s» no va por Efectos" % clave)
		_ok(int(d.get("p", 1)) in [2, 3], "A: «%s» tiene prioridad %d (2-3: una victoria o un jefe la bajan)" % [clave, int(d.get("p", 1))])
		_ok(int(d.get("max", 2)) == 1, "A: «%s» puede sonar %d veces a la vez (una)" % [clave, int(d.get("max", 2))])
		_ok(float(d.get("espera", 0.0)) >= 0.25, "A: «%s» se puede repetir enseguida (espera %.2f)" % [clave, float(d.get("espera", 0.0))])
		_ok(not d.get("en_bucle", false) and not d.get("bucle", false), "A: «%s» no debe ser un bucle" % clave)
		if clave in ESCUELAS:
			_ok(int(d.get("n", 1)) == 2, "A: «%s» debería alternar dos variantes" % clave)
		var e: Array = ESPERADO[clave]
		for ruta in _rutas(clave):
			_ok(not "suno" in ruta.to_lower(), "A: %s parece de Suno" % ruta)
			_ok(ruta.begins_with(Son.MAGIA_NEGRA) and ruta.get_extension() == "ogg", "A: %s no es un OGG de %s" % [ruta, Son.MAGIA_NEGRA])
			if not ResourceLoader.exists(ruta):
				_fallo("A: falta %s («%s»)" % [ruta, clave])
				continue
			var s = load(ruta)
			if not s is AudioStreamOggVorbis:
				_fallo("A: %s no carga como AudioStreamOggVorbis" % ruta)
				continue
			var largo: float = s.get_length()
			_ok(largo >= float(e[0]) and largo <= float(e[1]), "A: %s dura %.2f s (esperaba %.2f-%.2f)" % [ruta, largo, e[0], e[1]])
			_ok(not s.loop, "A: %s está marcado como bucle (.import)" % ruta)
			var f := FileAccess.open(ruta, FileAccess.READ)
			if f != null:
				bytes += f.get_length()
			archivos += 1
			_ok(ruta.get_file() in informe, "A: %s no tiene su fila en %s" % [ruta.get_file(), INFORME])
			print("ARCHIVO %-44s %5.2f s %6.1f KB" % [ruta, largo, (f.get_length() if f else 0) / 1024.0])
	_ok(bytes / 1024.0 <= PRESUPUESTO_KB, "A: los OGG de la magia negra ocupan %.0f KB (presupuesto %d)" % [bytes / 1024.0, PRESUPUESTO_KB])
	for palabra in ["Sonniss", "GDC", "licencia", "SHA-256"]:
		_ok(palabra in informe, "A: el informe no habla de «%s»" % palabra)
	# Las tablas de magia_negra.gd piden exactamente estas claves (ni una de más, ni una sin usar).
	var pedidas := {}
	var pares: Array = []
	for fam in MN.SONIDO:
		pares.append(MN.SONIDO[fam])
	for forma in MN.SONIDO_FORMA:
		pares.append(MN.SONIDO_FORMA[forma])
	pares.append(MN.SONIDO_PREPARAR)
	pares.append(MN.SONIDO_ROTO)
	for par in pares:
		pedidas[par[0]] = true
		_ok(Son.EFECTOS_MAGIA_NEGRA.has(par[0]), "A: magia_negra.gd pide «%s», que no está en EFECTOS_MAGIA_NEGRA" % par[0])
		_ok(Son.EFECTOS.has(par[1]), "A: el respaldo «%s» de «%s» no existe" % [par[1], par[0]])
	for clave in ESPERADO:
		_ok(pedidas.has(clave), "A: «%s» no lo pide nadie en magia_negra.gd" % clave)
	# Con la comprobación de combate.gd, cada hechizo elige la clave nueva (no su respaldo).
	var cb = load("res://combate.gd").new()
	var existe := Callable(cb, "_existe_sonido")
	var n_hechizos := 0
	for fam in MN.ESCUELAS:
		for nv in range(1, MN.cuantos(fam) + 1):
			var dh: Dictionary = MN.datos(fam, nv)
			var k: String = MN.sonido(fam, dh["forma"], existe)
			_ok(Son.EFECTOS_MAGIA_NEGRA.has(k), "A: %s pediría «%s» (respaldo): combate.gd no ve EFECTOS_MAGIA_NEGRA" % [dh["nombre"], k])
			n_hechizos += 1
	_ok(MN.sonido_de(MN.SONIDO_PREPARAR, existe) == "negra_preparar", "A: preparar pediría su respaldo")
	_ok(MN.sonido_de(MN.SONIDO_ROTO, existe) == "negra_conjuro_roto", "A: la rotura pediría su respaldo")
	cb.free()
	_ok(n_hechizos == 24, "A: %d hechizos (esperaba 24)" % n_hechizos)
	# Papeles en la mezcla: los avanzados por encima de las escuelas; preparar por debajo de todo.
	var db_escuela := -100.0
	for k in ESCUELAS:
		db_escuela = maxf(db_escuela, float(Son.definicion(k)["db"]))
	for k in AVANZADOS:
		_ok(float(Son.definicion(k)["db"]) > db_escuela + 2.0, "A: «%s» no va por encima de las escuelas" % k)
	for k in ESPERADO:
		if k != "negra_preparar":
			_ok(float(Son.definicion("negra_preparar")["db"]) <= float(Son.definicion(k)["db"]), "A: preparar suena más que «%s»" % k)
	print("OGG de la magia negra: %d archivos, %.0f KB" % [archivos, bytes / 1024.0])
	hechos.append("catálogo (%d claves, %d archivos, %.0f KB; 24 hechizos con clave propia)" % [ESPERADO.size(), archivos, bytes / 1024.0])


# ---------------------------------------------------------------- B. señal decodificada
func _senal() -> void:
	var probe: AudioStreamPlayback = (load(_rutas("negra_fuego")[0]) as AudioStream).instantiate_playback()
	if probe == null or not probe.has_method("mix_audio"):
		print("AVISO: este Godot no tiene AudioStreamPlayback.mix_audio: la señal no se mide aquí (sí en el informe)")
		return
	var hz := AudioServer.get_mix_rate()
	var bloque := int(0.02 * hz)
	var niveles := {}                                      # archivo → energía máxima en 400 ms (dB)
	for clave in ESPERADO:
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
			var bloques: Array = []
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
			var ventana := 0.0                                 # energía máxima en 400 ms (20 bloques)
			for k in range(0, maxi(1, bloques.size() - 19)):
				var w := 0.0
				for j in range(k, mini(bloques.size(), k + 20)):
					w += bloques[j]
				ventana = maxf(ventana, w)
			var nivel := 10.0 * log(ventana / (2.0 * 20 * bloque) + 1e-20) / log(10.0)
			niveles[ruta.get_file()] = nivel
			print("SEÑAL %-18s pico %6.1f dBFS  RMS %6.1f  400 ms %6.1f  arranca %.2f s  pico de energía %.2f s  tras el final %6.1f" % [
				ruta.get_file(), pico_db, rms, nivel, arranque, i_mx * 0.02, cola_db])
			_ok(rms > -40.0, "B: %s casi mudo (RMS %.1f dBFS)" % [ruta, rms])
			_ok(pico_db <= -0.5, "B: %s satura (pico %.1f dBFS)" % [ruta, pico_db])
			_ok(cola_db < -70.0, "B: %s sigue sonando después del final (%.1f dBFS)" % [ruta, cola_db])
			if clave in SIN_GOLPE:
				_ok(i_mx * 0.02 >= 0.3, "B: %s no crece: su pico está a los %.2f s (debe juntarse, sin golpe)" % [ruta, i_mx * 0.02])
			else:
				_ok(arranque >= 0.0 and arranque <= 0.15, "B: %s tarda %.2f s en arrancar (suena en el impacto)" % [ruta, arranque])
	if not niveles.is_empty():
		var lo := 1000.0
		var hi := -1000.0
		for k in niveles:
			lo = minf(lo, niveles[k])
			hi = maxf(hi, niveles[k])
		_ok(hi - lo <= 4.0, "B: los archivos no tienen el mismo nivel (400 ms: de %.1f a %.1f dB)" % [lo, hi])
		print("Nivel de archivo (400 ms): de %.1f a %.1f dB" % [lo, hi])
	hechos.append("señal")


# ---------------------------------------------------------------- C. reproducción con Sonido.efecto
func _reproduccion() -> void:
	Son.cortar("", 0.0)
	await _esperar(2)
	for clave in ESPERADO:
		var d: Dictionary = Son.definicion(clave)
		Son.reloj += 5.0
		var antes := int(Son.contador.get(clave, 0))
		var p = Son.efecto(clave)
		if p == null:
			_fallo("C: «%s» no suena con Sonido.efecto" % clave)
			continue
		_ok(String(p.bus) == "Efectos", "C: «%s» sale por %s" % [clave, p.bus])
		_ok(absf(p.volume_db - float(d["db"])) <= 0.8, "C: «%s» suena a %.1f dB (catálogo %.1f)" % [clave, p.volume_db, float(d["db"])])
		var otra = Son.efecto(clave)                           # pedida otra vez enseguida: no se duplica
		_ok(otra == null, "C: «%s» pedida dos veces seguidas suena dos veces" % clave)
		_ok(int(Son.contador.get(clave, 0)) == antes + 1, "C: «%s» cuenta %d reproducciones (una)" % [clave, int(Son.contador.get(clave, 0)) - antes])
		if clave in ESCUELAS:                                  # alternan sus dos variantes
			var primera: String = String(Son.registro[-1][2])
			Son.reloj += 5.0
			Son.efecto(clave)
			var segunda: String = String(Son.registro[-1][2])
			_ok(primera != segunda, "C: «%s» repite la misma variante (%s)" % [clave, primera.get_file()])
		Son.cortar(clave, 0.0)
	Son.pausado = true
	Son.reloj += 5.0
	_ok(Son.efecto("negra_juicio") == null, "C: en pausa suena «negra_juicio»")
	Son.pausado = false
	Son.cortar("", 0.0)
	await _esperar(2)
	hechos.append("reproducción (Efectos, volumen, sin duplicar, variantes, pausa)")


# ---------------------------------------------------------------- D. en un combate de verdad
func _limpiar_metas() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa",
			"magia_negra_v12", "magia_negra_v12_todo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _heroe(n: String) -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == n:
			return h
	return {}


func _combate() -> void:
	_limpiar_metas()
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya"])
	for n in {"Kael": 12, "Lya": 10}:
		G.datos()[n]["nivel"] = {"Kael": 12, "Lya": 10}[n]
		G.datos()[n]["libros"] = {}
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("magia_negra_v12", "Kael")
	Engine.set_meta("magia_negra_v12_todo", true)
	Engine.set_meta("zona", "desierto")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 1)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	c.MODO_PRUEBAS = false
	c.sonido_pedido.connect(func(n): pedidos.append(n))
	for en in c.enemigos:
		en["atb"] = 0.0
		en["hp_max"] = 400
		en["hp"] = 400
	await _esperar(60)
	c.set_process(false)                                   # combate parado: sin turnos
	var kael := _heroe("Kael")
	_ok(not kael.is_empty(), "D: no está Kael")
	if kael.is_empty():
		return
	kael["mp_max"] = 400
	kael["mp"] = 400
	var cuenta := 0
	for fam in MN.ESCUELAS:
		for nv in range(1, MN.cuantos(fam) + 1):
			var d: Dictionary = MN.datos(fam, nv)
			var clave: String = (MN.SONIDO_FORMA.get(d["forma"], MN.SONIDO[fam]) as Array)[0]
			var respaldo: String = (MN.SONIDO_FORMA.get(d["forma"], MN.SONIDO[fam]) as Array)[1]
			var objs: Array = c.enemigos.duplicate() if d["a"] == "enemigos" or d.has("saltos") else [c.enemigos[1]]
			var desde := pedidos.size()
			var antes := int(Son.contador.get(clave, 0))
			var desc_antes := _descartes(clave)
			c.actor = kael
			c._resolver_negra(kael, fam, nv, objs)
			var f := 0
			while kael.get("animando", false) and f < 400:
				await process_frame
				f += 1
			var nuevos: Array = pedidos.slice(desde)
			_ok(nuevos.count(clave) == 1 and nuevos.count(respaldo) == 0, "D: %s pide %s (debía «%s» una vez)" % [d["nombre"], nuevos, clave])
			_ok(int(Son.contador.get(clave, 0)) == antes + 1, "D: %s suena %d veces («%s»)" % [d["nombre"], int(Son.contador.get(clave, 0)) - antes, clave])
			_ok(_descartes(clave) == desc_antes, "D: %s: «%s» descartado (%s)" % [d["nombre"], clave, Son.descartes])
			for e in c.enemigos:
				e["hp"] = e["hp_max"]
				e["quemadura"] = 0
				e.erase("mn")
				c._quitar_nodo_negra(e, "mn_marca_nodo")
				c._quitar_nodo_negra(e, "mn_prision_nodo")
			cuenta += 1
			await _esperar(36)                                 # más que la espera más larga del catálogo (1 s)
	_ok(cuenta == 24, "D: %d hechizos (esperaba 24)" % cuenta)
	# preparar (Lluvia de Brasas) y que se lo rompan con un golpe del 25 %. Antes, lo que siga sonando (sin driver de
	# audio, un reproductor puede no terminar nunca y ocupar su voz; en el juego, los efectos acaban solos).
	var ocupadas: Array = []
	for v in Son._voces.get("Efectos", []):
		if v.playing:
			ocupadas.append("%s(p%d)" % [v.get_meta("efecto", "?"), int(v.get_meta("p", 0))])
	print("Voces de Efectos ocupadas antes de preparar: %d %s" % [ocupadas.size(), ocupadas])
	Son.cortar("", 0.0)
	await _esperar(3)
	var desde := pedidos.size()
	var prep_antes := int(Son.contador.get("negra_preparar", 0))
	var roto_antes := int(Son.contador.get("negra_conjuro_roto", 0))
	c.actor = kael
	c._lanzar_negra("negra_fuego", 3, c.enemigos.duplicate())
	await _esperar(30)
	_ok(kael.has("conjuro"), "D: Lluvia de Brasas no prepara")
	c._quitar_pv(kael, ceili(kael["hp_max"] * 0.25))
	await _esperar(10)
	var nuevos: Array = pedidos.slice(desde)
	_ok(nuevos.count("negra_preparar") == 1 and nuevos.count("embuir") == 0, "D: preparar pide %s" % [nuevos])
	_ok(nuevos.count("negra_conjuro_roto") == 1 and nuevos.count("barrera_rota") == 0, "D: la rotura pide %s" % [nuevos])
	_ok(int(Son.contador.get("negra_preparar", 0)) == prep_antes + 1, "D: preparar suena %d veces (descartes %s)" % [
		int(Son.contador.get("negra_preparar", 0)) - prep_antes, Son.descartes])
	_ok(int(Son.contador.get("negra_conjuro_roto", 0)) == roto_antes + 1, "D: la rotura suena %d veces (descartes %s)" % [
		int(Son.contador.get("negra_conjuro_roto", 0)) - roto_antes, Son.descartes])
	for r in Son.registro:
		if String(r[1]).begins_with("negra_"):
			_ok(String(r[3]) == "Efectos", "D: «%s» sonó por %s" % [r[1], r[3]])
	c.queue_free()
	c = null
	await _esperar(5)
	hechos.append("combate (24 hechizos, preparar y rotura: clave nueva, una vez, por Efectos)")


func _descartes(clave: String) -> int:
	var n := 0
	for k in Son.descartes:
		if String(k).begins_with(clave + ":"):
			n += int(Son.descartes[k])
	return n
