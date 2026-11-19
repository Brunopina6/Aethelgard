extends SceneTree
# Lo que sale DE VERDAD por el altavoz (T-030, D-067): con ventana y el driver de audio real, graba el bus Master
# (AudioEffectRecord) unos segundos en cada contexto y mide su nivel. Deja los WAV en <carpeta> para escucharlos.
# Distingue «reproducción iniciada» (hay señal) de la escucha real, que hace una persona.
#   Godot --path aethelgard --script res://pruebas/prueba_musica_senal.gd --fixed-fps 30 -- <carpeta> sin_prologo
# FALLO si algún contexto con pista no da señal, o si «carga» (silencio controlado) suena.

const SEGUNDOS := 5.0

var Mus
var fallos: Array = []


func _initialize() -> void:
	_grabar.call_deferred()


# Espera en tiempo REAL (con --fixed-fps el juego puede ir más deprisa que el reloj y el audio va al ritmo real).
func _real(segundos: float) -> void:
	var fin := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < fin:
		await process_frame


func _nivel(w: AudioStreamWAV) -> Array:
	var b: PackedByteArray = w.data
	var n := b.size() / 2
	var s := 0.0
	var pico := 0.0
	for i in range(0, n, 2):                       # cada dos: basta para el nivel y va el doble de rápido
		var v := b.decode_s16(i * 2) / 32768.0
		s += v * v
		pico = maxf(pico, absf(v))
	var rms := sqrt(s / maxf(1.0, n / 2.0))
	return [20.0 * log(maxf(rms, 1e-6)) / log(10.0), 20.0 * log(maxf(pico, 1e-6)) / log(10.0)]


func _grabar() -> void:
	var salida: String = OS.get_cmdline_user_args()[0]
	Mus = root.get_node("Musica")
	var rec := AudioEffectRecord.new()
	AudioServer.add_bus_effect(0, rec)
	var tramos := [["carga", "carga"], ["mapa", "mapa"], ["pradera", "pradera"], ["bosque", "bosque"],
		["desierto", "desierto"], ["mazmorra", "mazmorra"], ["ciudad", "ciudad"]]   # (19/11, C-10: Oakhaven 3D, la ciudad, el barrio y la muestra)
	for t in tramos:
		Mus.pedir(t[1])
		await _real(2.5)                           # el fundido de entrada (2 s) ya ha terminado
		rec.set_recording_active(true)
		await _real(SEGUNDOS)
		rec.set_recording_active(false)
		_medir(rec.get_recording(), salida, t[0], t[1] == "carga")
	# el combate: su propia música (combate.gd), por el bus Musica; la exploración se calla
	load("res://grupo.gd").datos()
	Engine.set_meta("grupo_activo", ["Kael"])
	Engine.set_meta("grupo_combate", 7)
	Engine.set_meta("tipo_combate", "normal")
	change_scene_to_file("res://combate.tscn")
	await _real(1.5)
	rec.set_recording_active(true)
	await _real(SEGUNDOS)
	rec.set_recording_active(false)
	_medir(rec.get_recording(), salida, "combate", false)
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _medir(w: AudioStreamWAV, salida: String, nombre: String, debe_callar: bool) -> void:
	if w == null:
		fallos.append("%s: no hay grabación (¿driver de audio?)" % nombre)
		return
	w.save_to_wav("%s/sonido_%s.wav" % [salida, nombre])
	var n := _nivel(w)
	print("SEÑAL %-9s RMS %6.1f dBFS · pico %6.1f dBFS · %.1f s grabados" % [nombre, n[0], n[1], w.get_length()])
	if debe_callar and n[0] > -70.0:
		fallos.append("%s debería ser silencio y da %.1f dBFS" % [nombre, n[0]])
	elif not debe_callar and n[0] < -60.0:
		fallos.append("%s no da señal (%.1f dBFS)" % [nombre, n[0]])
