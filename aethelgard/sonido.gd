extends Node
# Sonido (autoload): buses y volúmenes del jugador (T-030, D-064).
# - Los buses están en default_bus_layout.tres: Musica, Efectos, Interfaz y Ambiente, todos hacia Master. Cada
#   reproductor elige el suyo: la música del combate y las campanas de la cinemática del mirador, Musica; Érebo y el
#   cofre, Efectos; los tonos de los menús y el sonido al escribir de los diálogos, Interfaz. Ambiente queda lista
#   para los sonidos de ambiente, que aún no hay.
# - El volumen de cada bus (de 0 a 100 %) se guarda en user://ajustes.cfg, aparte de la partida, y solo cuando el
#   jugador lo cambia: abrir el juego no escribe nada.
# - Con todo al 100 %, todo suena igual que antes de los buses (0 dB en cada uno).
# Los ajustes se cambian en la pestaña «Ajustes» del menú del grupo (menus.gd).

const ARCHIVO := "user://ajustes.cfg"
const BUSES := ["Musica", "Efectos", "Interfaz", "Ambiente"]
const VISIBLES := ["Musica", "Efectos", "Interfaz"]       # Ambiente saldrá cuando haya algo que suene ahí
const NOMBRES := {"Musica": "Música", "Efectos": "Efectos", "Interfaz": "Interfaz", "Ambiente": "Ambiente"}
const AYUDA := {"Musica": "combates y cinemáticas", "Efectos": "magia, invocaciones y cofres",
	"Interfaz": "botones, menús y diálogos", "Ambiente": "el sonido de los lugares"}
const PASO := 10                                           # lo que sube o baja cada pulsación, en %
const HZ := 11025                                          # las muestras de los ajustes: cortas y ligeras

var _volumen := {}
var _muestras := {}                                        # bus → reproductor de su muestra en los ajustes
var _sonidos := {}                                         # bus → AudioStreamWAV de su muestra (se hace una vez)


func _ready() -> void:
	cargar()


# Lee los volúmenes guardados (sin archivo, o con un valor que no es un número, 100 %) y los aplica a los buses.
func cargar() -> void:
	var c := ConfigFile.new()
	var hay := c.load(ARCHIVO) == OK
	for b in BUSES:
		var v = c.get_value("volumen", b, 100) if hay else 100
		_volumen[b] = clampi(int(v), 0, 100) if (v is int or v is float) else 100
		_aplicar(b)


func volumen(bus: String) -> int:
	return int(_volumen.get(bus, 100))


# Cambia el volumen de un bus (se queda entre 0 y 100) y lo guarda.
func fijar(bus: String, v: int) -> void:
	if not bus in BUSES:
		return
	v = clampi(v, 0, 100)
	if v == volumen(bus):
		return
	_volumen[bus] = v
	_aplicar(bus)
	_guardar()


func _aplicar(bus: String) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		push_warning("Sonido: falta el bus «%s» (default_bus_layout.tres)" % bus)
		return
	var v := volumen(bus)
	AudioServer.set_bus_mute(i, v == 0)
	AudioServer.set_bus_volume_db(i, linear_to_db(v / 100.0) if v > 0 else -80.0)


func _guardar() -> void:
	var c := ConfigFile.new()
	c.load(ARCHIVO)                                        # conserva lo demás que hubiera en el archivo
	for b in BUSES:
		c.set_value("volumen", b, volumen(b))
	var err := c.save(ARCHIVO)
	if err != OK:
		push_warning("Sonido: no se pudieron guardar los ajustes (%s)" % error_string(err))


# Una muestra corta por ese bus, para oír el volumen nuevo al cambiarlo en los ajustes: dos notas de campana
# (música), un destello de tres notas (efectos) o un «tic» (interfaz). Cada pulsación vuelve a empezar la muestra: no
# se amontonan. Son sonidos hechos por código, cortos y a 11 025 Hz, para que la primera pulsación no dé un parón
# (la campana del mirador, de 2,5 s, tardaba unos 180 ms en el PC la primera vez).
func probar(bus: String) -> void:
	if volumen(bus) == 0 or not bus in VISIBLES:
		return
	if not _sonidos.has(bus):
		_sonidos[bus] = _wav(_muestra(bus), HZ)
	var p: AudioStreamPlayer = _muestras.get(bus)
	if p == null:
		p = AudioStreamPlayer.new()
		p.bus = bus
		p.volume_db = -6.0
		add_child(p)
		_muestras[bus] = p
	p.stream = _sonidos[bus]
	p.play()


static func _muestra(bus: String) -> PackedFloat32Array:
	var m := PackedFloat32Array()
	match bus:
		"Musica":                                          # sol y do, con timbre de campana suave
			var notas := PackedFloat32Array([784.0, 1046.5])
			m.resize(int(HZ * 0.55))
			for i in m.size():
				var t := float(i) / HZ
				var s := 0.0
				for k in 2:
					var t0 := t - k * 0.16
					if t0 >= 0.0:
						s += (sin(TAU * notas[k] * t0) + 0.3 * sin(TAU * 2.0 * notas[k] * t0)) * minf(1.0, t0 * 250.0) * exp(-t0 * 6.0)
				m[i] = s * 0.22
		"Efectos":                                         # tres notas agudas y rápidas, como un destello
			var notas := PackedFloat32Array([1568.0, 2093.0, 2637.0])
			m.resize(int(HZ * 0.32))
			for i in m.size():
				var t := float(i) / HZ
				var s := 0.0
				for k in 3:
					var t0 := t - k * 0.06
					if t0 >= 0.0:
						s += sin(TAU * notas[k] * t0) * minf(1.0, t0 * 400.0) * exp(-t0 * 14.0)
				m[i] = s * 0.18
		"Interfaz":                                        # «tic» cristalino, como el de los menús
			m.resize(int(HZ * 0.06))
			for i in m.size():
				var t := float(i) / HZ
				m[i] = (sin(TAU * 2600.0 * t) + 0.5 * sin(TAU * 3900.0 * t)) * exp(-t * 85.0) * 0.22
	return m


static func _wav(m: PackedFloat32Array, hz: int) -> AudioStreamWAV:
	var b := PackedByteArray()
	b.resize(m.size() * 2)
	for i in m.size():
		b.encode_s16(i * 2, int(clampf(m[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = hz
	w.stereo = false
	w.data = b
	return w
