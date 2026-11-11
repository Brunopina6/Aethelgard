extends SceneTree
# V12 (11/11): el sonido del Mar de Cristal (EFECTOS_DESIERTO de sonido.gd, OGG de audio/desierto/). Sin ventana y muda:
# comprueba que cada sonido está, carga, dura lo que debe y es (o no) un bucle; no cómo se oye (eso, en las muestras para
# escuchar: docs/memory/agents/sonido_v12_desierto.md).
#   A. Cada clave existe (definicion()), no pisa una de EFECTOS, va por un bus de sonido.gd y cada archivo (con sus
#      variantes) es un AudioStreamOggVorbis de audio/desierto/ con la duración esperada, marcado como bucle solo si lo
#      es («bucle» o emisor «tres_d»), que cabe en su presupuesto y tiene su fila en el informe de procedencia; nada de Suno.
#   B. Señal decodificada (mix_audio de la reproducción, si este Godot lo tiene): ni muda ni saturada; los bucles siguen
#      sonando al dar la vuelta; la tormenta, más fuerte que el viento en calma; el pitido raro, más agudo que el normal.
#   C. Se piden con lo de siempre: efecto() (el rugido, el temblor con «pos», la pala alterna sus variantes, dos pitidos
#      seguidos) y fuente_3d() (la fogata y el oasis, en bucle, por Ambiente); ruta_de() da el archivo de los dos vientos;
#      y las claves de antes siguen en audio/efectos/ y en WAV.
# Datos aislados (ejecutar_pruebas.ps1); no guarda partida.
#   Godot --headless --path aethelgard --script res://pruebas/prueba_audio_desierto.gd --fixed-fps 30

const INFORME := "docs/memory/agents/sonido_v12_desierto.md"   # relativo a la raíz del repositorio
# clave → [duración mínima, máxima] (s, cada variante) y si es un bucle
const ESPERADO := {
	"desierto_viento": [30.0, 60.0, true], "desierto_tormenta": [20.0, 60.0, true],
	"fogata_bucle": [8.0, 30.0, true], "oasis_bucle": [12.0, 40.0, true],
	"gusano_rugido": [2.0, 8.0, false], "gusano_temblor": [2.0, 8.0, false],
	"excavar_arena": [0.5, 3.0, false], "buscador_pitido": [0.05, 0.4, false], "buscador_pitido_raro": [0.05, 0.4, false],
}
const PRESUPUESTO_KB := 1700                               # todos los OGG juntos (medido el 11/11: 1 380 KB)

var Son
var fallos := 0
var hechos: Array = []
var limite_ms := 0
var nivel := {}                                            # clave → RMS decodificado (dBFS) de su primer archivo
var zcr := {}                                              # clave → cruces por cero por segundo / 2 (Hz aproximados)


func _initialize() -> void:
	limite_ms = Time.get_ticks_msec() + 100 * 1000
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


func _probar() -> void:
	Son = root.get_node("Sonido")
	await _esperar(3)
	_catalogo()
	_senal()
	await _peticiones()
	print("OK audio del desierto: ", ", ".join(hechos))
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


# ---------------------------------------------------------------- A. catálogo, archivos, bucles, memoria e informe
func _catalogo() -> void:
	var raiz := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var informe := FileAccess.get_file_as_string(raiz.path_join(INFORME))
	if informe == "":
		_fallo("A: no se puede leer %s" % INFORME)
	if Son.EFECTOS_DESIERTO.size() != ESPERADO.size():
		_fallo("A: EFECTOS_DESIERTO tiene %d claves (esperaba %d)" % [Son.EFECTOS_DESIERTO.size(), ESPERADO.size()])
	var bytes := 0
	for clave in ESPERADO:
		var d: Dictionary = Son.definicion(clave)
		if d.is_empty() or not Son.EFECTOS_DESIERTO.has(clave):
			_fallo("A: falta «%s» en sonido.gd (EFECTOS_DESIERTO)" % clave)
			continue
		if Son.EFECTOS.has(clave):
			_fallo("A: «%s» está también en EFECTOS" % clave)
		if not String(d.get("bus", "Efectos")) in Son.BUSES:
			_fallo("A: «%s» va por un bus que no es de sonido.gd" % clave)
		var e: Array = ESPERADO[clave]
		var bucle: bool = bool(d.get("bucle", false)) or (d.has("tres_d") and not d["tres_d"].has("cada"))
		if bucle != bool(e[2]):
			_fallo("A: «%s»: el catálogo %s lo trata como bucle" % [clave, "sí" if bucle else "no"])
		for ruta in _rutas(clave):
			if "suno" in ruta.to_lower():
				_fallo("A: %s parece de Suno" % ruta)
			if not ruta.begins_with(Son.DESIERTO) or ruta.get_extension() != "ogg":
				_fallo("A: %s no es un OGG de %s" % [ruta, Son.DESIERTO])
			if not ResourceLoader.exists(ruta):
				_fallo("A: falta %s («%s»)" % [ruta, clave])
				continue
			var s = load(ruta)
			if not s is AudioStreamOggVorbis:
				_fallo("A: %s no carga como AudioStreamOggVorbis" % ruta)
				continue
			var largo: float = s.get_length()
			if largo < float(e[0]) or largo > float(e[1]):
				_fallo("A: %s dura %.2f s (esperaba entre %.2f y %.2f)" % [ruta, largo, e[0], e[1]])
			if s.loop != bool(e[2]):
				_fallo("A: %s %s está marcado como bucle (.import)" % [ruta, "no" if e[2] else "sí y no debería"])
			var f := FileAccess.open(ruta, FileAccess.READ)
			if f != null:
				bytes += f.get_length()
			if not ruta.get_file() in informe:
				_fallo("A: %s no tiene su fila en %s" % [ruta.get_file(), INFORME])
			print("ARCHIVO %-48s %6.2f s  bucle %-5s  %6.1f KB" % [ruta, largo, s.loop, (f.get_length() if f else 0) / 1024.0])
	if bytes / 1024.0 > PRESUPUESTO_KB:
		_fallo("A: los OGG del desierto ocupan %.0f KB (presupuesto %d)" % [bytes / 1024.0, PRESUPUESTO_KB])
	for palabra in ["Sonniss", "GDC", "licencia"]:
		if not palabra in informe:
			_fallo("A: el informe no habla de «%s»" % palabra)
	print("OGG del desierto: %.0f KB" % (bytes / 1024.0))
	hechos.append("catálogo (%d claves, %.0f KB)" % [ESPERADO.size(), bytes / 1024.0])


# ---------------------------------------------------------------- B. señal decodificada
func _senal() -> void:
	var probe: AudioStreamPlayback = (load(_rutas("buscador_pitido")[0]) as AudioStream).instantiate_playback()
	if probe == null or not probe.has_method("mix_audio"):
		print("AVISO: este Godot no tiene AudioStreamPlayback.mix_audio: la señal no se mide aquí (sí en el informe)")
		return
	var hz := AudioServer.get_mix_rate()
	for clave in ESPERADO:
		var bucle: bool = ESPERADO[clave][2]
		for ruta in _rutas(clave):
			var s: AudioStream = load(ruta)
			if s == null:
				continue
			var pb := s.instantiate_playback()
			pb.start(0.0)
			var n := int(s.get_length() * hz)
			var extra := int(0.5 * hz)                         # medio segundo más allá del final
			var buf: PackedVector2Array = pb.mix_audio(1.0, n + extra)
			if buf.size() < n - int(0.01 * hz):                # el remuestreo puede dejar unas pocas muestras menos
				_fallo("B: %s: solo se decodifican %d de %d muestras" % [ruta, buf.size(), n])
				continue
			n = mini(n, buf.size())
			var pico := 0.0
			var suma := 0.0
			var cruces := 0
			var ant := 0.0
			for i in n:
				var v := (buf[i].x + buf[i].y) * 0.5
				pico = maxf(pico, maxf(absf(buf[i].x), absf(buf[i].y)))
				suma += buf[i].x * buf[i].x + buf[i].y * buf[i].y
				if (v > 0.0) != (ant > 0.0):
					cruces += 1
				ant = v
			var rms := 10.0 * log(suma / (2.0 * n) + 1e-20) / log(10.0)
			var pico_db := 20.0 * log(pico + 1e-12) / log(10.0)
			var cola := 0.0
			for i in range(n, mini(buf.size(), n + extra)):
				cola += buf[i].x * buf[i].x + buf[i].y * buf[i].y
			var cola_db := 10.0 * log(cola / (2.0 * extra) + 1e-20) / log(10.0)
			var inicio := 0.0                                  # el primer medio segundo: tras la vuelta debe sonar igual
			for i in mini(extra, n):
				inicio += buf[i].x * buf[i].x + buf[i].y * buf[i].y
			var inicio_db := 10.0 * log(inicio / (2.0 * extra) + 1e-20) / log(10.0)
			print("SEÑAL %-26s pico %6.1f dBFS  RMS %6.1f  inicio %6.1f  tras el final %6.1f" % [ruta.get_file(), pico_db, rms,
				inicio_db, cola_db])
			if rms < -45.0:
				_fallo("B: %s casi mudo (RMS %.1f dBFS)" % [ruta, rms])
			if pico_db > -0.3:
				_fallo("B: %s satura (pico %.1f dBFS)" % [ruta, pico_db])
			if bucle and (cola_db < -60.0 or absf(cola_db - inicio_db) > 3.0):
				_fallo("B: %s no vuelve a empezar al dar la vuelta (%.1f frente a %.1f dBFS al principio)" % [ruta, cola_db,
					inicio_db])
			if not bucle and cola_db > -70.0:
				_fallo("B: %s sigue sonando después del final (%.1f dBFS)" % [ruta, cola_db])
			if not nivel.has(clave):
				nivel[clave] = rms
				zcr[clave] = cruces / 2.0 / (n / hz)
	if nivel.size() == ESPERADO.size():
		var calma: float = nivel["desierto_viento"] + float(Son.definicion("desierto_viento")["db"])
		var tormenta: float = nivel["desierto_tormenta"] + float(Son.definicion("desierto_tormenta")["db"])
		print("VIENTO en calma %.1f dB · tormenta %.1f dB (con el volumen del catálogo)" % [calma, tormenta])
		if tormenta < calma + 5.0:
			_fallo("B: la tormenta (%.1f) no queda al menos 5 dB por encima del viento en calma (%.1f)" % [tormenta, calma])
		print("PITIDOS normal ~%.0f Hz · raro ~%.0f Hz (cruces por cero)" % [zcr["buscador_pitido"], zcr["buscador_pitido_raro"]])
		if zcr["buscador_pitido_raro"] < zcr["buscador_pitido"] * 1.3:
			_fallo("B: el pitido raro no es más agudo que el normal")
	hechos.append("señal")


# ---------------------------------------------------------------- C. se piden con lo de siempre
func _limpiar() -> void:
	for p in Son._todas():
		Son._parar_fundido(p)
		p.stop()
	Son._bajar_hasta.clear()
	Son._ultimo.clear()
	Son.reiniciar_contadores()


func _peticiones() -> void:
	_limpiar()
	for clave in ["gusano_rugido", "gusano_temblor", "buscador_pitido", "buscador_pitido_raro", "excavar_arena"]:
		var p = Son.efecto(clave, {"pos": Vector3(70, 0, 35)} if clave.begins_with("gusano") else {})
		if p == null:
			_fallo("C: efecto(«%s») no suena (descartes: %s)" % [clave, Son.descartes])
			continue
		if not p.stream is AudioStreamOggVorbis or String(p.bus) != String(Son.definicion(clave).get("bus", "Efectos")):
			_fallo("C: «%s» no suena con su OGG por su bus (%s)" % [clave, p.bus])
	# la pala: dos paladas seguidas usan las dos variantes
	var usadas := {}
	for i in 2:
		Son._ultimo.clear()
		Son.efecto("excavar_arena")
		usadas[String(Son.registro[-1][2])] = true
	if usadas.size() != 2:
		_fallo("C: dos paladas seguidas repiten la misma variante (%s)" % usadas.keys())
	# dos pitidos rápidos suenan los dos (el buscador cerca)
	_limpiar()
	await _esperar(2)
	Son.efecto("buscador_pitido")
	await _esperar(3)                                          # 0,1 s (más que su espera de 0,05 s)
	if Son.efecto("buscador_pitido") == null or int(Son.contador.get("buscador_pitido", 0)) != 2:
		_fallo("C: dos pitidos a 0,1 s no suenan los dos (%d)" % int(Son.contador.get("buscador_pitido", 0)))
	# los emisores de la fogata y el oasis
	var escena := Node3D.new()
	escena.name = "PruebaDesierto"
	root.add_child(escena)
	for clave in ["fogata_bucle", "oasis_bucle"]:
		var e: AudioStreamPlayer3D = Son.fuente_3d(escena, clave, Vector3(36, 0, 92))
		if e == null:
			_fallo("C: fuente_3d(«%s») no crea el emisor" % clave)
			continue
		if not e.stream is AudioStreamOggVorbis or not e.stream.loop or String(e.bus) != "Ambiente" or not e.playing:
			_fallo("C: el emisor «%s» no suena en bucle por Ambiente" % clave)
	await _esperar(5)
	escena.queue_free()
	await _esperar(2)
	# los dos vientos, por su ruta (para Musica u otro reproductor) y las claves de antes, donde estaban
	for clave in ["desierto_viento", "desierto_tormenta"]:
		var r: String = Son.ruta_de(clave)
		if not r.begins_with(Son.DESIERTO) or not ResourceLoader.exists(r):
			_fallo("C: ruta_de(«%s») = «%s»" % [clave, r])
	var antes := {"golpe": "res://audio/efectos/combate/golpe_1.wav", "rio": "res://audio/efectos/ambiente/rio.wav",
		"cofre": "res://audio/efectos/mundo/cofre_1.wav", "ui_tic": ""}
	for clave in antes:
		if Son.ruta_de(clave) != antes[clave]:
			_fallo("C: ruta_de(«%s») = «%s» (esperaba «%s»)" % [clave, Son.ruta_de(clave), antes[clave]])
	_limpiar()
	if Son.efecto("golpe") == null or not String(Son.registro[-1][2]).begins_with("res://audio/efectos/combate/golpe_"):
		_fallo("C: «golpe» ya no suena desde audio/efectos/")
	_limpiar()
	hechos.append("peticiones")
