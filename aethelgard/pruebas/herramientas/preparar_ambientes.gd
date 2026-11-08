extends SceneTree
# Prepara los ambientes del juego (T-030, D-067) a partir de sonidos CC0 de la biblioteca del usuario
# (D:\qtorrent\sound effect: la colección «500 GAME SOUND EFFECTS», con la fuente de cada archivo en LICENSES.txt).
# Para cada ambiente: lee el WAV de origen, mezcla si hace falta un segundo sonido por debajo (p. ej. viento bajo los
# pájaros), funde los últimos segundos con el principio para que el bucle no se note al repetirse, y lo guarda en
# res://audio/ambiente/<nombre>.wav con su .import (bucle hacia delante y compresión QOA: ligero en el móvil).
# Uso (con los datos aislados, como las pruebas):
#   Godot --headless --path aethelgard --script res://pruebas/herramientas/preparar_ambientes.gd -- "D:/qtorrent/sound effect"
# Después hay que importar (Godot --headless --path aethelgard --import). La procedencia está en docs/audio.

const SALIDA := "res://audio/ambiente"
const FUNDIDO := 2.0                               # segundos que se funden del final al principio
const MAX_SEGUNDOS := 32.0                         # bucles de 32 s como mucho: bastan y pesan la mitad en Git
const RMS_OBJETIVO := 0.06                         # sonoridad media parecida en todos (unos -24 dBFS)...
const PICO_MAX := 0.9                              # ...sin que ningún pico llegue a saturar

# nombre: [origen, ganancia, mezcla (origen o ""), ganancia de la mezcla]
const AMBIENTES := {
	"pradera": ["15_nature_weather/birds_48kHz_16bit_30.69s_02_s39.wav", 0.9,
		"15_nature_weather/wind_48kHz_16bit_60s_01_s20.wav", 0.28],
	"bosque": ["16_ambiences/forest_48kHz_16bit_30s_01_s29.wav", 0.9, "", 0.0],
	"viento": ["15_nature_weather/wind_48kHz_16bit_60s_02_s20.wav", 0.55, "", 0.0],
	"mazmorra": ["16_ambiences/dungeon_loop_48kHz_16bit_94.31s_01_s08.wav", 0.8, "", 0.0],
	"desierto": ["16_ambiences/desert_48kHz_16bit_35.81s_01_s29.wav", 0.8, "", 0.0],
}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("FALLO: falta la carpeta de la biblioteca (-- \"D:/qtorrent/sound effect\")")
		quit(1)
		return
	var base: String = args[0].replace("\\", "/")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SALIDA))
	var fallos := 0
	for nombre in AMBIENTES:
		var d: Array = AMBIENTES[nombre]
		var w := AudioStreamWAV.load_from_file(base.path_join(d[0]))
		if w == null or w.format != AudioStreamWAV.FORMAT_16_BITS or not w.stereo:
			print("FALLO: %s no se puede leer como WAV de 16 bits estéreo" % d[0])
			fallos += 1
			continue
		var m: PackedFloat32Array = _muestras(w, d[1])
		if d[2] != "":
			var w2 := AudioStreamWAV.load_from_file(base.path_join(d[2]))
			if w2 == null or w2.mix_rate != w.mix_rate or not w2.stereo:
				print("FALLO: la mezcla %s no encaja" % d[2])
				fallos += 1
				continue
			var m2 := _muestras(w2, d[3])
			for i in mini(m.size(), m2.size()):
				m[i] += m2[i]
		var maximo := int((MAX_SEGUNDOS + FUNDIDO) * w.mix_rate) * 2
		if m.size() > maximo:
			m.resize(maximo)
		var bucle := _bucle(m, int(FUNDIDO * w.mix_rate))
		var rms_antes := _rms(bucle)
		var pico_antes := _pico(bucle)
		var ganancia := minf(RMS_OBJETIVO / maxf(rms_antes, 0.0001), PICO_MAX / maxf(pico_antes, 0.0001))
		for i in bucle.size():
			bucle[i] *= ganancia
		print("  %s: RMS %.4f → %.4f, pico %.2f → %.2f (×%.1f)" % [nombre, rms_antes, _rms(bucle), pico_antes,
			_pico(bucle), ganancia])
		var salida := AudioStreamWAV.new()
		salida.format = AudioStreamWAV.FORMAT_16_BITS
		salida.mix_rate = w.mix_rate
		salida.stereo = true
		salida.data = _pcm(bucle)
		var ruta := "%s/%s.wav" % [SALIDA, nombre]
		var err := salida.save_to_wav(ruta)
		if err != OK:
			print("FALLO: no se pudo guardar %s (%s)" % [ruta, error_string(err)])
			fallos += 1
			continue
		_import(ruta)
		print("AMBIENTE %s: %.1f s, %d Hz estéreo, pico %.2f (de %s%s)" % [nombre, bucle.size() / 2.0 / w.mix_rate,
			w.mix_rate, _pico(bucle), d[0].get_file(), "" if d[2] == "" else " + " + d[2].get_file()])
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


# PCM de 16 bits estéreo intercalado → flotantes (-1..1) por la ganancia.
static func _muestras(w: AudioStreamWAV, ganancia: float) -> PackedFloat32Array:
	var b: PackedByteArray = w.data
	var n := b.size() / 2
	var m := PackedFloat32Array()
	m.resize(n)
	for i in n:
		m[i] = b.decode_s16(i * 2) / 32768.0 * ganancia
	return m


# Bucle sin corte: el principio se funde (potencia constante) con lo que había justo antes del final, y el final se
# corta ahí. Al repetirse, la última muestra enlaza con la que la seguía en la grabación.
static func _bucle(m: PackedFloat32Array, f: int) -> PackedFloat32Array:
	var cuadros := m.size() / 2
	f = mini(f, cuadros / 3)
	var largo := cuadros - f
	var r := PackedFloat32Array()
	r.resize(largo * 2)
	for i in largo:
		for c in 2:
			var v: float = m[i * 2 + c]
			if i < f:
				var t := float(i) / f
				v = v * sin(t * PI / 2.0) + m[(largo + i) * 2 + c] * cos(t * PI / 2.0)
			r[i * 2 + c] = v
	return r


static func _pcm(m: PackedFloat32Array) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(m.size() * 2)
	for i in m.size():
		b.encode_s16(i * 2, int(clampf(m[i], -1.0, 1.0) * 32767.0))
	return b


static func _rms(m: PackedFloat32Array) -> float:
	var s := 0.0
	for v in m:
		s += v * v
	return sqrt(s / maxf(1.0, m.size()))


static func _pico(m: PackedFloat32Array) -> float:
	var p := 0.0
	for v in m:
		p = maxf(p, absf(v))
	return p


# Ajustes de importación: bucle hacia delante en todo el archivo y compresión QOA. Godot los respeta al importar.
static func _import(ruta: String) -> void:
	var c := ConfigFile.new()
	c.set_value("remap", "importer", "wav")
	c.set_value("remap", "type", "AudioStreamWAV")
	c.set_value("deps", "source_file", ruta)
	c.set_value("params", "force/8_bit", false)
	c.set_value("params", "force/mono", false)
	c.set_value("params", "force/max_rate", false)
	c.set_value("params", "force/max_rate_hz", 44100)
	c.set_value("params", "edit/trim", false)
	c.set_value("params", "edit/normalize", false)
	c.set_value("params", "edit/loop_mode", 2)
	c.set_value("params", "edit/loop_begin", 0)
	c.set_value("params", "edit/loop_end", -1)
	c.set_value("params", "compress/mode", 2)
	c.save(ruta + ".import")
