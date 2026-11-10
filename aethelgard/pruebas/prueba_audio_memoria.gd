extends SceneTree
# Memoria del audio (T-083, tanda 7): cuánto ocupa en la RAM y en el paquete cada sonido del juego. Sin ventana, muda.
# - RAM: un AudioStreamWAV (o MP3) se carga entero en memoria; se mide el tamaño de sus datos (data.size(), lo que
#   ocupan comprimidos: QOA en los WAV) y, además, cuánto sube la memoria estática al cargarlos todos.
# - Paquete: lo que entra en la APK es el recurso importado (.godot/imported/*.sample o el .mp3/.ogg): su tamaño.
# Por carpeta, los 15 más grandes y el formato de cada uno (QOA o PCM, mono o estéreo, frecuencia, duración).
# Comprueba: todos los WAV del juego (fuera de addons/) en QOA; los bucles con la frecuencia que dice FRECUENCIA (bajada
# solo donde lo que hay por encima de la nueva mitad queda más de 50 dB por debajo: medido el 09/11); y que el audio no
# pase de PRESUPUESTO_MB en la RAM.
#   Godot --headless --path aethelgard --script res://pruebas/prueba_audio_memoria.gd --fixed-fps 30 -- [<carpeta>]
# Con una carpeta, deja ahí memoria_audio.csv (una fila por sonido).

const CARPETAS := ["res://audio/", "res://sonidos/", "res://"]
const PRESUPUESTO_MB := 21.0                              # medido el 09/11: 22,45 MB antes de la tanda 7; 19,47 después
# Bucles largos cuya frecuencia se bajó al importar (force/max_rate; tanda 7): lo que tienen por encima de la nueva mitad
# quedaba entre 52 y 81 dB por debajo del total (espectro medido el 09/11). Los demás bucles (bosque, río, cascadas, la
# fuente) tienen agua u hojas por encima de 12 kHz y se quedan a 48 kHz.
const FRECUENCIA := {
	"res://audio/ambiente/viento.wav": 22050, "res://audio/efectos/ambiente/viento_abismo.wav": 22050,
	"res://audio/efectos/ambiente/taberna.wav": 22050, "res://audio/efectos/ambiente/plaza_murmullo.wav": 22050,
	"res://audio/efectos/ambiente/mercado_murmullo.wav": 22050,
	"res://audio/ambiente/pradera.wav": 32000, "res://audio/ambiente/mazmorra.wav": 32000,
	"res://audio/ambiente/desierto.wav": 32000,
}

var fallos := 0


func _initialize() -> void:
	_medir.call_deferred()


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _medir() -> void:
	var args := OS.get_cmdline_user_args()
	var salida: String = args[0] if args.size() > 0 and not args[0].contains("=") else ""
	var rutas := PackedStringArray()
	_buscar("res://audio/", rutas, true)
	_buscar("res://sonidos/", rutas, true)
	_buscar("res://", rutas, false)                         # las músicas de la raíz (combate)
	var antes := Performance.get_monitor(Performance.MEMORY_STATIC)
	var filas: Array = []
	var cargados: Array = []                                  # que no se liberen mientras se mide la memoria
	for ruta in rutas:
		var s = load(ruta)
		if s == null:
			_fallo("no se carga %s" % ruta)
			continue
		cargados.append(s)
		var ram := 0
		var formato := "?"
		var hz := 0
		var estereo := false
		if s is AudioStreamWAV:
			ram = s.data.size()
			formato = ["8 bits", "16 bits", "IMA-ADPCM", "QOA"][s.format]
			hz = s.mix_rate
			estereo = s.stereo
			if s.format != AudioStreamWAV.FORMAT_QOA and not ruta.begins_with("res://addons/"):
				_fallo("%s no está en QOA (%s)" % [ruta, formato])
			if FRECUENCIA.has(ruta) and hz != int(FRECUENCIA[ruta]):
				_fallo("%s va a %d Hz y debería ir a %d (bucle bajado al importar)" % [ruta, hz, FRECUENCIA[ruta]])
		elif s is AudioStreamMP3 or s is AudioStreamOggVorbis:
			ram = s.data.size() if s is AudioStreamMP3 else 0
			formato = "MP3" if s is AudioStreamMP3 else "Ogg Vorbis"
		var paquete := _importado(ruta)
		filas.append([ruta, formato, hz, estereo, s.get_length(), ram, paquete])
	var despues := Performance.get_monitor(Performance.MEMORY_STATIC)
	var ram_total := 0
	var paquete_total := 0
	var por_carpeta := {}
	for f in filas:
		ram_total += int(f[5])
		paquete_total += int(f[6])
		var c: String = String(f[0]).get_base_dir()
		var a: Array = por_carpeta.get(c, [0, 0, 0])
		por_carpeta[c] = [a[0] + 1, a[1] + int(f[5]), a[2] + int(f[6])]
	print("MEMORIA_AUDIO %d sonidos · RAM (datos) %.2f MB · paquete %.2f MB · memoria estática +%.2f MB al cargarlos" % [
		filas.size(), ram_total / 1048576.0, paquete_total / 1048576.0, (despues - antes) / 1048576.0])
	for c in por_carpeta:
		print("CARPETA %-36s %3d sonidos · RAM %6.2f MB · paquete %6.2f MB" % [c, por_carpeta[c][0], por_carpeta[c][1] / 1048576.0,
			por_carpeta[c][2] / 1048576.0])
	filas.sort_custom(func(a, b): return int(a[5]) > int(b[5]))
	for k in mini(15, filas.size()):
		var f: Array = filas[k]
		print("GRANDE %-58s %-9s %5d Hz %s %5.1f s · RAM %7.1f KB" % [f[0], f[1], f[2], "estéreo" if f[3] else "mono   ", f[4],
			int(f[5]) / 1024.0])
	if ram_total / 1048576.0 > PRESUPUESTO_MB:
		_fallo("el audio ocupa %.1f MB en la RAM (presupuesto %.0f MB)" % [ram_total / 1048576.0, PRESUPUESTO_MB])
	if salida != "":
		var t := PackedStringArray(["ruta;formato;hz;estereo;segundos;ram_bytes;paquete_bytes"])
		for f in filas:
			t.append("%s;%s;%d;%s;%.2f;%d;%d" % [f[0], f[1], f[2], "si" if f[3] else "no", f[4], f[5], f[6]])
		var fa := FileAccess.open(salida.path_join("memoria_audio.csv"), FileAccess.WRITE)
		if fa != null:
			fa.store_string("\n".join(t) + "\n")
			fa.close()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


# Los .wav, .mp3 y .ogg de una carpeta (y sus subcarpetas si «hondo»), sin addons/ ni .godot/.
func _buscar(carpeta: String, rutas: PackedStringArray, hondo: bool) -> void:
	var d := DirAccess.open(carpeta)
	if d == null:
		return
	for f in d.get_files():
		var ruta := carpeta.path_join(f)
		if f.get_extension().to_lower() in ["wav", "mp3", "ogg"] and not ruta in rutas:
			rutas.append(ruta)
	if hondo:
		for sub in d.get_directories():
			if not sub.begins_with("."):
				_buscar(carpeta.path_join(sub), rutas, true)


# El tamaño del recurso importado (lo que va en el paquete): el «path» de su .import.
func _importado(ruta: String) -> int:
	var c := ConfigFile.new()
	if c.load(ruta + ".import") != OK:
		return 0
	var p: String = c.get_value("remap", "path", "")
	if p == "":
		return 0
	var fa := FileAccess.open(p, FileAccess.READ)
	return int(fa.get_length()) if fa != null else 0
